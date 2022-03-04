#!/usr/bin/env perl
use strict;
use warnings;
# Reference:   https://jakebits.wordpress.com/tag/mod_perl/
use Apache2::Request;
use Apache2::Response;
use Apache2::Const -compile => qw(OK NOT_FOUND LOG_INFO);
#use APR::Const -compile => qw(ENOTIME);
use JSON;
#use DateTime;
#use Data::Dumper;
use DBI;
use CGI;

my $dsn = "DBI:mysql:database=employees:host=localhost:port='3306'";
my $User = "perl";
my $Passwd = "perlperl";
my $table ="employees";
my $r = shift;
my $req = Apache2::Request->new($r);
my @fields;
my @Data;
my $iFilteredTotal;
my $iTotal;
my @values;
my @columns = qw/first_name last_name gender emp_no birth_date hire_date/;
my $q = new CGI; # send http header

my $sql = "SELECT first_name, last_name, gender, emp_no, birth_date, hire_date from employees";
#SQL_CALC_FOUND_ROWS, it is possible to use this mothed to count the rows.

my $dbh = DBI->connect($dsn, $User, $Passwd);

# -- Filtering
my $searchValue = $req->param->{'search[value]'};
if( $searchValue ne '' ) {
    $sql .= ' WHERE (';
    $sql .= 'emp_no LIKE ? OR birth_date LIKE ? or first_name LIKE ? or last_name LIKE ?
            or gender LIKE ? or hire_date LIKE ?)';
    push @values, ('%'. $searchValue .'%','%'. $searchValue .'%','%'. $searchValue .'%','%'. $searchValue .'%',
            '%'. $searchValue.'%', '%'. $searchValue .'%');
}

my $sql_filter = $sql;
my @values_filter = @values;

# -- Ordering
my $sortColumnId = $req->param->{'order[0][column]'};
my $sortColumnName = "";
my $sortDir = "";

if ( $sortColumnId ne '' ) {
    $sql .= ' ORDER BY ';
    $sortColumnName = $columns[$sortColumnId];
    $sortDir = $req->param->{'order[0][dir]'};
    $sql .= $sortColumnName . ' ' . $sortDir;
}

## total rows
my $s1th = $dbh->prepare('select count(*) from employees');
$s1th->execute();
my $temp = $s1th->fetchrow_hashref();
my $count = $temp->{'count(*)'};
$s1th->finish;

# Paging, get 'length' & 'start'
my $limit = $req->param('length') || 10;
if ($limit == -1) {
    $limit = $count;
}   ## It is too slow to show 5,000,000 on one page, so I disabled to show all in mainpage.js. But this is Ok if there is now so much items.
my $offset="0";
if($req->param('start') ) {
  $offset = $req->param('start');
}

  $sql .= " LIMIT ? OFFSET ? ";
  push @values, $limit;
  push @values, $offset;




# ## total rows
# my $s1th = $dbh->prepare('select count(*) from employees');
# $s1th->execute();
# my $temp = $s1th->fetchrow_hashref();
# my $count = $temp->{'count(*)'};
# $s1th->finish;


#*************************************
my $sth1 = $dbh->prepare($sql_filter);
$sth1->execute(@values_filter);
my $filterCount = $sth1->rows;
$sth1->finish;
## rows after filter*******************



my $sth = $dbh->prepare($sql);
$sth->execute(@values);


# output hash
my %output = (
       "draw" => $req->param('draw'),
        "recordsTotal" => $count,
        "recordsFiltered" => $filterCount
    );


my $rowcount = 0;
my $dataElement = "";
# fetching the different rows data.
while(my @aRow = $sth->fetchrow_array) {
        my @row = ();

        for (my $i = 0; $i < @columns; $i++) {
            # looping thru different columns, pushing data to an array.
            $dataElement = "";
            $dataElement = $aRow[$i];
            push @row, $dataElement;

        }
        push @row, $rowcount;
        # add each row data to hash collection.
        @{$output{'data'}}[$rowcount] = [@row];
        $rowcount++;
}

unless($rowcount) {
    $output{'data'} = '';  #we don't want to have 'null'. will break js
}

#covert the hash to string format.
my $json_response =  \%output;

# add response header, important
print $q->header('content-type: application/json \n\n');
####  Or Apache2::Response

# convert the response data to JSON format
my $jsonOutput = encode_json $json_response;
print $jsonOutput;

#DESC exsample database ########################################
# | emp_no     | int(11)       | NO   | PRI | NULL    |       |
# | birth_date | date          | NO   |     | NULL    |       |
# | first_name | varchar(14)   | NO   |     | NULL    |       |
# | last_name  | varchar(16)   | NO   |     | NULL    |       |
# | gender     | enum('M','F') | NO   |     | NULL    |       |
# | hire_date  | date          | NO   |     | NULL    |       |
