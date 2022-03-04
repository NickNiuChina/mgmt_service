use File::Basename;

my @client_req_files = glob "$ENV{CARELSERVICEDIR}/*.req"; 
for my $file (@client_req_files) {
    my $filename = basename($file);
    next unless (length($filename) == 40);
    print $filename . "\n";
}


# stat
# my @array = stat("README.md");
#    print "$array[10]\n";

# ordering
# my @array = (19,9,45,43,3,5,56);
# @word = sort { $a cmp $b } @array;
# print "$_" . "\n" for (@word);

print "$ENV{CARELSERVICEDIR}";
