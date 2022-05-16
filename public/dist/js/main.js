$(document).ready(function () {

  // update the fname in the input 
  $(".custom-file > input").on("change", function () {
    var filePath = $(this).val();
    if (filePath.length > 0) {
      var arr = filePath.split('\\');
      var fileName = arr[arr.length - 1];
      $('.custom-file-label').text(fileName);
    } else {
      $('.custom-file-label').text("Please select Req file to upload");
    }
  })

  $("#tbreqfiles").DataTable({
    "dom": 'Blfrtip',
    "responsive": true, "lengthChange": false, "autoWidth": false,
    // "responsive": true, "lengthChange": true, "autoWidth": true,
    "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
    "lengthMenu": [5, 50, 100, 1000],
    "processing": true,
    "serverSide": true,
    // "searching": true,
    "destroy": true,
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
    "columnDefs": [{
      "targets": 3,
      "data": null,
      "render": function (data, type, row) {
        var id = '"' + row.id + '"';
        var html = "<a href='javascript:void(0);'  class='reqDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#reqDelModal'  ><i class='fa fa-times'></i> Delete</a>"
        // html += "<a href='javascript:void(0);'   onclick='deleteThisRowPapser(" + id + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
        html += "<a href='javascript:void(0);' class='reqDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
        return html;
      }
    }],
  });

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
    "destroy": true,
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
    // datatable inline-button
    // https://datatables.net/reference/option/columnDefs
    "columnDefs": [{
      "targets": 3,
      "data": null,
      "render": function (data, type, row) {
        var id = '"' + row.id + '"';
        var html = "<a href='javascript:void(0);'  class='certDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#certDelModal'  ><i class='fa fa-times'></i> Delete</a>"
        // html += "<a href='javascript:void(0);'   onclick='deleteCertByFilename(" + 99 + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
        html += "<a href='javascript:void(0);' class='certDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
        return html;
      }
    }],
  });

  // delete req files
  // $('#tbreqfiles tbody').on('click', '.reqDelete', function () {
  //   var reqFileName = $(this).parent().parent().children(".dtr-control").text();
  //   // console.log(certFileName);
  //   $.post("/service/reqs/delete", { 'filename': reqFileName }, function (result) {
  //     console.log(result)
  //     $('#tbreqfiles').DataTable().ajax.reload();
  //   });
  // });
  // delete req files with warning modal
  $('#reqDelModal').on('show.bs.modal',
    function (e) {
      var reqFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
      $(this).on('click', '.btn-danger', { 'filename': reqFileName }, function (e) {
        // alert("Deleted!!");
        $.post("/service/reqs/delete", { 'filename': reqFileName }, function (result) {
          // console.log(result)
          $('#tbreqfiles').DataTable().ajax.reload(); // reload table data
        });
        $('#reqDelModal').modal('hide'); // hide modal
      });
    })

  // delete cert files
  // $('#tbcertfiles tbody').on('click', '.certDelete', function () {
  //   var certFileName = $(this).parent().parent().children(".dtr-control").text();
  //   // console.log(certFileName);
  //   $.post("/service/certed/delete", { 'filename': certFileName }, function (result) {
  //     console.log(result)
  //     $('#tbcertfiles').DataTable().ajax.reload();
  //   });
  // });
  // delete cert files with warning modal
  $('#certDelModal').on('show.bs.modal',
    function (e) {
      var certFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
      $(this).on('click', '.btn-danger', { 'filename': certFileName }, function (e) {
        // alert("Deleted!!");
        $.post("/service/certed/delete", { 'filename': certFileName }, function (result) {
          // console.log(result)
          $('#tbcertfiles').DataTable().ajax.reload();
        });
        $('#certDelModal').modal('hide'); // hide modal
      });
    })

  // req files download
  $('#tbreqfiles tbody').on('click', '.reqDownload', function () {
    var reqFileName = $(this).parent().parent().children(".dtr-control").text();
    //Set the File URL.
    var url = "/service/reqs/dl/" + reqFileName;
    console.log(url);
    $.ajax({
      url: url,
      cache: false,
      xhr: function () {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
          if (xhr.readyState == 2) {
            if (xhr.status == 200) {
              xhr.responseType = "blob";
            } else {
              xhr.responseType = "text";
            }
          }
        };
        return xhr;
      },
      success: function (data) {
        //Convert the Byte Data to BLOB object.
        var blob = new Blob([data], { type: "application/octetstream" });

        //Check the Browser type and download the File.
        var isIE = false || !!document.documentMode;
        if (isIE) {
          window.navigator.msSaveBlob(blob, reqFileName);
        } else {
          var url = window.URL || window.webkitURL;
          link = url.createObjectURL(blob);
          var a = $("<a />");
          a.attr("download", reqFileName);
          a.attr("href", link);
          $("body").append(a);
          a[0].click();
          $("body").remove(a);
        }
      }
    });
  });

  // cert files download
  $('#tbcertfiles tbody').on('click', '.certDownload', function () {
    var certFileName = $(this).parent().parent().children(".dtr-control").text();
    //Set the File URL.
    var url = "/service/reqs/dl/" + certFileName;
    console.log(url);
    $.ajax({
      url: url,
      cache: false,
      xhr: function () {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
          if (xhr.readyState == 2) {
            if (xhr.status == 200) {
              xhr.responseType = "blob";
            } else {
              xhr.responseType = "text";
            }
          }
        };
        return xhr;
      },
      success: function (data) {
        //Convert the Byte Data to BLOB object.
        var blob = new Blob([data], { type: "application/octetstream" });

        //Check the Browser type and download the File.
        var isIE = false || !!document.documentMode;
        if (isIE) {
          window.navigator.msSaveBlob(blob, certFileName);
        } else {
          var url = window.URL || window.webkitURL;
          link = url.createObjectURL(blob);
          var a = $("<a />");
          a.attr("download", certFileName);
          a.attr("href", link);
          $("body").append(a);
          a[0].click();
          $("body").remove(a);
        }
      }
    });
  });

});