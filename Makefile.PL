use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#Changes: in 1.04, changed MM::needs to MY::needs. (oops!)

WriteMakefile(
    'NAME'	=> 'Religion',
    'VERSION'	=> '1.04',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    #'INST_BOOT' => '',
    #'INST_DYNAMIC' => '',
    #'INST_STATIC' => '',
    
    #'XS'	=> '',
    #'LDFROM' => '',
    #'OBJECT' => '',
   # 'PM' => { "Religion.pm" => "\$(INST_LIB)/Religion.pm" },
);


sub MY::needs_linking { 
        return 0;
}
        
