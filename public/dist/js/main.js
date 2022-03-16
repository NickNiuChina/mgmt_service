$(function () {
  $("#tbcertfiles").DataTable({
    "dom": 'Blfrtip',
    "responsive": true, "lengthChange": false, "autoWidth": false,
    // "responsive": true, "lengthChange": true, "autoWidth": true,
    "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
    "lengthMenu": [5, 50, 100, 1000],
    //
    "processing": true,
    "serverSide": true,
    // "searching": true,
    // "destroy": true,
    "paging": false,
    // "pagingType": 'input',
    "ordering": false,
    // "iDisplayLength": 10,
    // "bLengthChange": true,
    // "lengthMenu": [20, 50, 100, 1000],
    "ajax": {
      'url': "/service/certed/list",
      'type': 'POST',
      'data': {},
      'dataType': 'json',
    },

  });
});

$(function () {
  $("#tbreqfiles").DataTable({
    "dom": 'Blfrtip',
    "responsive": true, "lengthChange": false, "autoWidth": false,
    // "responsive": true, "lengthChange": true, "autoWidth": true,
    "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
    "lengthMenu": [5, 50, 100, 1000],
    //
    "processing": true,
    "serverSide": true,
    // "searching": true,
    // "destroy": true,
    "paging": false,
    // "pagingType": 'input',
    "ordering": false,
    // "iDisplayLength": 10,
    // "bLengthChange": true,
    // "lengthMenu": [20, 50, 100, 1000],
    "ajax": {
      'url': "/service/reqs/list",
      'type': 'POST',
      'data': {},
      'dataType': 'json',
    },

  });
});

// datatable 行内添加按钮
// https://blog.csdn.net/qq_40127253/article/details/81478881

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