use Religion;

$Warn::PreHandler = new WarnPreHandler sub {
	print "This is a warn prehandler. Currently, it does nothing.\n";
	next;
};
eval 'warn "Test warning"';

$Die::Handler = new DieHandler sub {
	my($a,$b,$level) = @_;
	print "Outside scope is at $level in DieHandler\n";
	next;
};

$Die::PreHandler = new DiePreHandler sub {
	my($a,$b,$level) = @_;
	print "Outside scope is at $level in DiePreHandler\n";
	next;
};

die "Dying now";



