// From AdminLte pages tables
// $(function () {
//     $("#example1").DataTable({
//       "responsive": true, "lengthChange": false, "autoWidth": false,
//       "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"]
//     }).buttons().container().appendTo('#example1_wrapper .col-md-6:eq(0)');
//     $('#example2').DataTable({
//       "paging": true,
//       "lengthChange": false,
//       "searching": false,
//       "ordering": true,
//       "info": true,
//       "autoWidth": false,
//       "responsive": true,
//     });
//   });

// From my perl page
  $(document).ready(function() {
    $('#emTable').dataTable( {
        "dom": 'Blfrtip',
        "buttons": ['copy', 'csv', 'excel', 'pdf', 'print'],
        "processing": true,
        "serverSide": true,
        "searching" : true,
		"destroy"   : true,
		"paging":     true, 
		"pagingType": 'input',
		"ordering"     : true,
		"iDisplayLength": 10,
		"bLengthChange" : true,
		"lengthMenu": [20, 50, 100, 1000], 
        // "blengthMenu": [ [10, 25, 50, -1], [10, 25, 50, "All"] ]
		"scrollY"       : '50vh',
        "ajax": {
        		'url':  "pscript/employee_info.pl",
        		'type': 'POST',
        		'data': {},
        		'dataType':  'json',
        		// error: function;,
    			},
        
    } );
} );