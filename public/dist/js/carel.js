$(function () {
  $("#tbcertfiles").DataTable({
    "responsive": true, "lengthChange": false, "autoWidth": false,
    "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
  }).buttons().container().appendTo('#tbcertfiles_wrapper .col-md-6:eq(0)');
  
});

// $('#example2').DataTable({
//   "paging": true,
//   "lengthChange": false,
//   "searching": false,
//   "ordering": true,
//   "info": true,
//   "autoWidth": false,
//   "responsive": true,
// });