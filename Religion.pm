package Religion;

#v3

sub import {} #nothing to export

sub TraceBack {
	# Given a starting scope offset, returns (get ready):
	#
	# Bool/Int: Am I in an eval?/How many evals are around me?
	# Integer: What is the line number of this scope?
	# String: What is the filename or eval number of this scope?
	# Integer: What is the line number of the nearest scope
	#          that is a file, not an eval?
	# String: What is the filename of the nearest scope that
	#         that is a file, not an eval?
	# String: If I were to print out a message to the user, what
	#         should I say to explain the relation of the nearest
	#         file scope to my current scope?

	my($level) = @_;
	my($iline) = (caller($level))[2];
	my($ifile) = (caller($level))[1];
	my($nil,$ofile,$oline,$sub);
	my($oscope)="";
	my($eval)=0;

  	while (($nil,$file,$line,$sub) = caller($level++)) {
	    if( $file =~ /^\(eval/ ) {
			$oline = (caller($level))[2];
			$oscope .= "the eval at line $oline of ";
			$eval++;
	    } else {
	    	return ($eval,$iline,$ifile,$line,$file,$oscope);
	    }
	}

	die "Unable to trace scope"; # This can't happen.

}	                                                                          

sub TraceBackHandler {
	my($sub,$oldhandler,$startlevel) = @_;
	
	return sub {
		my($msg,$fmsg,@trace,$level,$eval);
		
		# This section has been moved out to $SIG{__DIE__} and WARN.
		
		#if(@_==1) {
		#	# Invoked by die(), warn(), etc.;
		#	$msg = $_[0];
		#	$msg =~ s/ at (\S+|\(.*\)) line \d+\.\n$//;
		#	$level=$startlevel;
		#	@trace = Religion::TraceBack($level+1);
		#
		#	$fmsg = $msg . ((substr($msg,-1,1) ne "\n") ?
		#				 " at line $trace[1] of $trace[5]$trace[4].\n"
		#				 #" at $trace[2] line $trace[1].\n"
		#				 : "");
		#} else {
			($msg,$fmsg,$level,@trace) = @_;
		#}
			
		my(@result);
		my($result)="last";
		#anonymous block:
		{ 

			@result=&$sub($msg,$fmsg,$level+1,@trace);
			$result="return";
			
			$msg = $result[0] if @result>0;
			$fmsg = $result[1] if @result>1;
			$level = $result[2]-1 if @result>2;
			@trace[0..$#result-3] = @result[3..$#result] if @result>3;
			
			if(@result==1) { 
				$fmsg = $msg . ((substr($msg,-1,1) ne "\n") ?
						 " at line $trace[1] of $trace[5]$trace[4].\n"
						 #" at $trace[2] line $trace[1].\n"
						 : "");
			}
			
		} continue {
			$result="next" if $result ne "return";
	
			if($oldhandler) {
				return &$oldhandler($msg,$fmsg,$level+1,@trace);
			}
		}
		
		# Return parsed info, whether we got single or multiple args
		if( $result eq "return") {
			($msg,$fmsg,$level,@trace);
		} elsif( $result eq "next") {
			next;
		} else {
			last;
		}
	}	
};


package Warn;

$Handler = $PreHandler = "";

$SIG{__WARN__} = sub {
	local($^W) = 0;
	my($msg,$fmsg,@trace,$level,@trace);

	$msg = $_[0];
	$msg =~ s/ at (\S+|\(.*\)) line \d+\.\n$//;
	$level=0;
	@trace = Religion::TraceBack($level+1);

	$fmsg = $msg . ((substr($msg,-1,1) ne "\n") ?
			 " at line $trace[1] of $trace[5]$trace[4].\n"
			 #" at $trace[2] line $trace[1].\n"
			 : "");
			 
	unshift(@trace,$msg,$fmsg,$level);

	my($ok)=0;
	{ 
			my(@result);
			@result=&$PreHandler(@trace) if $PreHandler;
					
			@trace[0..$#result]=@result;
	} continue {
			$ok=1;
	} 
	return if !$ok;

	my($ok)=0;
	{
			my(@result);
			@result=&$Handler(@trace) if $Handler;
			
			#$result[2]++ if $#result>=2;
			@trace[0..$#result]=@result;
	} continue {
		$ok=1;
	}
	return if !$ok;
	
	warn($trace[1]);
};

package WarnHandler;

sub new {
	my($pkg,$sub) = @_;
	return Religion::TraceBackHandler ($sub,$Warn::Handler,0);
};

package WarnPreHandler;

sub new {
	my($pkg,$sub) = @_;
	return Religion::TraceBackHandler ($sub,$Warn::PreHandler,0);
};


package Die;

$Handler = $PreHandler = "";

$SIG{__DIE__} = sub {
	local($^W) = 0; # This cuts out warnings about exiting subs via
					# next or last.
	my($msg,$fmsg,@trace,$level,@trace);

	$msg = $_[0];
	$msg =~ s/ at (\S+|\(.*\)) line \d+\.\n$//;
	$level=0;
	@trace = Religion::TraceBack($level+1);

	$fmsg = $msg . ((substr($msg,-1,1) ne "\n") ?
			 " at line $trace[1] of $trace[5]$trace[4].\n"
			 #" at $trace[2] line $trace[1].\n"
			 : "");
			 
	unshift(@trace,$msg,$fmsg,$level);
	
	my($ok)=0;
	{ 
			my(@result);
			@result = &$PreHandler(@trace) if $PreHandler;
				
			#$result[2]++ if $#result>=2;
			@trace[0..$#result]=@result;
	} continue {
			$ok=1;
	} 
	die($trace[1]) if !$ok;

	my($ok)=0;
	{
			my(@result);
			@result = &$Handler(@trace) if $Handler;
			
			#$result[2]++ if $#result>=2;
			@trace[0..$#result]=@result;
	} continue {
		$ok=1;
	}
	
	die($trace[1]);
};

package DieHandler;

sub new {
	my($pkg,$sub) = @_;
	return Religion::TraceBackHandler ($sub,$Die::Handler,0);
};

package DiePreHandler;

sub new {
	my($pkg,$sub) = @_;
	return Religion::TraceBackHandler ($sub,$Die::PreHandler,0);
};


package Religion;


1;

__END__;

=head1 NAME

Religion - Generate tracebacks and create and install die() and
 warn() handlers.

=head1 DESCRIPTION

This is a second go at a module to simplify installing die() and warn()
handlers, and to make such handlers easier to write and control.

For most people, this just means that if use C<use Religion;> then you'll
get noticably better error reporting from warn() and die(). This is especially
useful if you are using eval().

Religion provides four classes, WarnHandler, DieHandler, WarnPreHandler, and
DiePreHandler, that when you construct them return closures that can be
stored in variables that in turn get invoked by $SIG{__DIE__} and
$SIG{__WARN__}. Note that if Religion is in use, you should not modify
$SIG{__DIE__} or $SIG{__WARN__}, unless you are careful about invoking
chaining to the old handler.

Religion also provides a TraceBack function, which is used by a DieHandler
after you C<die()> to give a better handle on the current scope of your
situation, and provide information about where you were, which might
influence where you want to go next, either returning back to where you
were, or going on to the very last. [Sorry - Ed.]

See below for usage and examples.

=head1 USAGE

=over 8

=item DieHandler SUB

Invoke like this:

 $Die::Handler = new DieHandler sub {
 	#...
 };

where C<#...> contains your handler code. Your handler will receive the
following arguments:

  $message, $full_message, $level, $eval, 
  		    $iline, $ifile, $oline, $ofile, $oscope

C<$message> is the message provided to die(). Note that the default addition
of " at FILE line LINE.\n" will have been stripped off if it was present.
If you want to add such a message back on, feel free to do so with $iline
and $ifile.

C<$full_message) is the message with a scope message added on if there was
no newline at the end of C<$message>. Currently,
this is I<not> the original message that die() tacked on, but something 
along the lines of " at line 3 of the eval at line 4 of Foo.pl\n".

C<$eval> is non-zero if the die() was invoked inside an eval.

The rest of the arguments are explained in the source for
Religion::TraceBack. Yes, I need to document these, but not just now, for
they are a pain to explain.


Whenever you install a DieHandler, it will automatically store the current
value of $Die::Handler so it can chain to it. If you want to install a 
handler only temporarily, use local().


If your handler returns data using C<return> or by falling off the end, 
then the items returns will be used to fill back in the argument list, and 
the next handler in the chain, if any, will be invoked. B<Don't fall off the
end if you don't want to change the error message.>

If your handler exits using C<last>, then no further handlers will be
invoked, and the program will die immediatly.

If your handler exits using C<next>, then the next handler in the chain will
be invoked directly, without giving you a chance to change its arguments as
you could if you used C<return>.

If your handler invokes die(), then die() will proceed as if no handlers
were installed. If you are inside an eval, then it will exit to the scope
enclosing the eval, otherwise it will exit the program.

=item WarnHandler SUB

Invoke like this:

 $Warn::Handler = new WarnHandler sub {
 	#...
 };
 
For the rest of its explanation, see DieHandler, and subsitute warn() for
die(). Note that once the last DieHandler completes (or C<last> is invoked)
then execution will return to the code that invoked warn().

=item DiePreHandler SUB

Invoke like this:

 $Die::PreHandler = new DiePreHandler sub {
 	#...
 };
 
This works identically to $Die::Handler, except that it forms a separate chain
that is invoked I<before> the DieHandler chain. Since you can use C<last> to
abort all the handlers and die immediately, or change the messages or scope
details, this can be useful for modifying data that all future handlers will
see, or to dispose of some messages from further handling.

This is even more useful in $Warn::PreHandler, since you can just throw
away warnings that you I<know> aren't needed.

=item WarnPreHandler SUB

Invoke like this:

 $Warn::PreHandler = new WarnPreHandler sub {
 	#...
 };
 
This works identically to $Warn::Handler, except that it forms a separate
chain that is invoked I<before> the WarnHandler chain. Since you can use
C<last> to abort all the handlers and return to the program, or change
the messages or scope details, this can be useful for modifying data that
all future handlers will see, or to dispose of some messages.

This is very useful, since you can just throw
away warnings that you I<know> aren't needed.

=back

=head1 EXAMPLES

=over 8

=item A dialog error message:

 $Die::Handler = new DieHandler sub {
    my($msg,$fmsg,$level,$eval) = @_;
    if($eval) {
 		# if we are in an eval, skip to the next handler
 		next;
 	} else {
 		# show a message box describing the error.
	 	print "ShowMessageBox $fmsg";
	 	
	 	# force the program to exit
	 	exit 0;
	 	next;
 	}
 };

=item A handler that changes die() messages back to the original format

 local($Die::Handler) = new DieHandler sub {
    my($msg,$fmsg,$level,@trace) = @_;

	$fmsg = $msg . ((substr($msg,-1,1) ne "\n") ?
				 " at $trace[2] line $trace[1].\n"
				 : "");
	return ($msg,$fmsg);
 };

=item A warn handler that does nothing.

 $Warn::Handler = new WarnHandler sub {next;};

=item A warn prehandler that throws away a warning.

 $Warn::PreHandler = new WarnPreHandler sub {
 	my($msg,$fmsg,$level,$eval) = @_;
 	if($msg =~ /Use of uninitialized/) {
 		last;
 	}
 	next;
 };

=back

=cut

