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
    "columnDefs" : [ {
      // 定义操作列
      "targets" : 3,//操作按钮目标列
      "data" : null,
      "render" : function(data, type, row) {
      var id = '"' + row.id + '"';
      var html = "<a href='javascript:void(0);'  class='delete btn btn-default btn-xs'  ><i class='fa fa-times'></i> Delete</a>"
      html += "<a href='javascript:void(0);'   onclick='deleteThisRowPapser("+ data[0] + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
      return html;
      }
    }],
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
    "columnDefs" : [ {
      // 定义操作列
      "targets" : 3,//操作按钮目标列
      "data" : null,
      "render" : function(data, type,row) {
      var id = '"' + row.id + '"';
      var html = "<a href='javascript:void(0);'  class='delete btn btn-default btn-xs'  ><i class='fa fa-times'></i> Delete</a>"
      html += "<a href='javascript:void(0);'   onclick='deleteThisRowPapser("+ id + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
      return html;
      }
    }],

  });
});

// datatable 行内添加按钮
// https://datatables.net/reference/option/columnDefs