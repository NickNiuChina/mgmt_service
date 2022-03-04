$(function () {
  $("#tbcertfiles").DataTable({
    "dom": 'Blfrtip',
    // "responsive": true, "lengthChange": false, "autoWidth": false,
    // "responsive": true, "lengthChange": true, "autoWidth": true,
    "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
    "lengthMenu": [5, 50, 100, 1000],
    //
    "processing": true,
    "serverSide": true,
    // "searching": true,
    // "destroy": true,
    // "paging": true,
    // "pagingType": 'input',
    // "ordering": true,
    // "iDisplayLength": 10,
    // "bLengthChange": true,
    // "lengthMenu": [20, 50, 100, 1000],
    "ajax": {
      'url': "pscript/employee_info.pl",
      'type': 'POST',
      'data': {},
      'dataType': 'json',
    },

  });

});



// $(function () {
//   $("#tbcertfiles").DataTable({
//     "dom": 'Blfrtip',
//     // "responsive": true, "lengthChange": false, "autoWidth": false,
//     // "responsive": true, "lengthChange": true, "autoWidth": true,
//     "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
//     // "lengthMenu": [5, 50, 100, 1000],
//   }).buttons().container().appendTo('#tbcertfiles_wrapper .col-md-6:eq(0)');

// });


// $('#example2').DataTable({
//   "paging": true,
//   "lengthChange": false,
//   "searching": false,
//   "ordering": true,
//   "info": true,
//   "autoWidth": false,
//   "responsive": true,
// });