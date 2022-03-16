use File::Basename;
use POSIX qw(strftime);
use Data::Dumper;
use Data::Printer;


  my @filearray = ();
  my $file;
  my $dir = $ENV{MGMTSERVICEDIR};

  my @client_req_files = glob "$ENV{MGMTSERVICEDIR}/*.req"; 
  for my $file (@client_req_files) {
    my $filename = basename($file);
    next unless (length($filename) == 40);
    next unless $filename =~ /zzhaVPcU-/ && 0;
    unshift @filearray, $filename;
  }

  # ordering by file name
  my @filesOrdered = reverse sort {$a cmp $b} @filearray;
  my $count = @filesOrdered;


  my @data;
  my $temp = [];
  my $createDate;

  for $file (@filesOrdered) {
      $createDate = strftime("%Y/%m/%d:%M:%S", localtime((stat "$dir/$file")[10] ));
      unshift @data, [$file, $createDate, 'NA', 'NA'] ;
  }

  my %output = (
        "draw" => 1,
        "recordsTotal" => $count,
        "recordsFiltered" => $count,
        'data'  => \@data
  );
 
p (%output);


# 
# {
#     "draw":"1",
#     "recordsTotal":300024,
#     "data":[
#         ["Aamer","Jayawardene","M",11935,"1963-03-23","1996-10-26",0],
#         ["Aamer","Glowinski","F",13011,"1955-02-25","1989-10-08",1],
#         ["Aamer","Kornyak","M",22279,"1959-01-30","1985-02-25",2],
#         ["Aamer","Parveen","F",20678,"1963-12-25","1987-03-25",3],
#         ["Aamer","Szmurlo","M",23269,"1952-02-15","1988-05-25",4],
#         ["Aamer","Garrabrants","M",12160,"1954-12-11","1989-09-19",5],
#         ["Aamer","Tsukuda","M",24404,"1960-04-21","1998-12-25",6],
#         ["Aamer","Fraisse","M",11800,"1958-12-09","1990-08-08",7],
#         ["Aamer","Kroll","F",28043,"1957-07-13","1986-05-17",8],
#         ["Aamer","Slutz","F",15332,"1961-12-29","1989-05-19",9]
#     ],
        
#     "recordsFiltered":"300024"
# }


















# stat
# my @array = stat("README.md");
#    print "$array[10]\n";

# ordering
# my @array = (19,9,45,43,3,5,56);
# @word = sort { $a cmp $b } @array;
# print "$_" . "\n" for (@word);

# print "$ENV{MGMTSERVICEDIR}";
