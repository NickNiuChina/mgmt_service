$(document).ready(function() {

    // if set these to local variable, will cause modal submit too many times
    var cn;
    var storename;

    function formatDate(date) {
        var d = new Date(date),
            month = '' + (d.getMonth() + 1),
            day = '' + d.getDate(),
            year = d.getFullYear();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        return [year, month, day].join('-');
    };

    function formatTime(date) {
        var d = new Date(date),
            month = '' + (d.getMonth() + 1),
            day = '' + d.getDate(),
            year = d.getFullYear(),
            hour = '' + d.getHours(),
            min = '' + d.getMinutes(),
            sec = '' + d.getSeconds();
        if (month.length < 2) month = '0' + month;
        if (day.length < 2) day = '0' + day;
        if (hour.length < 2) {
            hour = '0' + hour;
        }
        if (min.length < 2) min = '0' + min;
        if (sec.length < 2) sec = '0' + sec;
        return [year, month, day].join('-') + "_" + [hour, min, sec].join(':');
    };

    $("#tbclientstatus").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": true,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        // "buttons": ["excel", "colvis"],
        "buttons": [{
                extend: 'excel',
                text: 'Excel',
                exportOptions: {
                    modifier: {
                        page: 'all',
                        selected: null,
                        search: 'none',
                    },
                    columns: [0, 1, 2, 3]
                },
            },
            // { extend: 'excel', text: '<i class="fas fa-file-excel" aria-hidden="true"> Excel </i>' },
            "colvis",
            "pageLength"
        ],
        "lengthMenu": [100, 50, 20, "1000"],
        "processing": true,
        "serverSide": true,
        "destroy": true,
        "paging": true,
        "ordering": true,
        "order": [5, "desc"],
        "ajax": {
            'url': "service/clientstatus/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        "columnDefs": [{
                "targets": 0,
                "data": null,
                "render": function(data, type, row) {
                    var temp = data[0] ? data[0] : "Unnamed";
                    var html = "<a href='javascript:void(0);'  class='clientstatus' data-toggle='modal' data-target='#clientStatusModal'>" + temp + "</a>"
                    return html;
                }
            },
            {
                "targets": 3,
                "data": null,
                "render": function(data, type, row) {
                    var rdate = new Date(data[3])
                        // console.log(formatTime(rdate));
                    return formatTime(rdate);
                }
            },
            {
                "targets": 4,
                "data": null,
                "render": function(data, type, row) {
                    var rdate = new Date(data[4])
                        // console.log(formatDate(rdate));
                    return formatDate(rdate);
                }
            },
            {
                "targets": 5,
                "data": null,
                "render": function(data, type, row) {
                    // console.log(data[5]);
                    var html = data[5] ? "<i class='fa fa-circle text-green'></i>" : "<i class='fa fa-circle text-red'></i>";
                    return html;
                }
            },
            {
                "targets": 6,
                "orderable": false,
                "data": null,
                "render": function(data, type, row) {
                    // console.log(data[5]);
                    if (data[5]) {
                        var reg = RegExp(/boss/);
                        if (data[1].length == 41 || reg.test(data[1])) {
                            var html = "<a href='javascript:void(0);' class='conn4ect443 btn btn-default btn-xs'><i class='far fa-arrow-alt-circle-right'></i> Mgmt</a>"
                            html += "<a href='javascript:void(0);' class='sshConnect btn btn-default btn-xs'><i class='fa fa-terminal'></i> SSH</a>"
                            return html;
                        } else {
                            var html = 'NotApplied';
                            return html;
                        }
                    } else {
                        var html = 'Unreachable';
                        return html;
                    }
                }
            },
        ],
    });

    $("#tuntbclientstatus").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": true,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        // "buttons": ["excel", "colvis"],
        "buttons": [{
                extend: 'excel',
                text: 'Excel',
                exportOptions: {
                    modifier: {
                        page: 'all',
                        selected: null,
                        search: 'none',
                    },
                    columns: [0, 1, 2, 3]
                },
            },
            // { extend: 'excel', text: '<i class="fas fa-file-excel" aria-hidden="true"> Excel </i>' },
            "colvis",
            "pageLength"
        ],
        "lengthMenu": [100, 50, 20, "1000"],
        "processing": true,
        "serverSide": true,
        "destroy": true,
        "paging": true,
        "ordering": true,
        "order": [5, "desc"],
        "ajax": {
            'url': "service/tunclientstatus/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        "columnDefs": [{
                "targets": 0,
                "data": null,
                "render": function(data, type, row) {
                    var temp = data[0] ? data[0] : "Unnamed";
                    var html = "<a href='javascript:void(0);'  class='clientstatus' data-toggle='modal' data-target='#tunclientStatusModal'>" + temp + "</a>"
                    return html;
                }
            },
            {
                "targets": 3,
                "data": null,
                "render": function(data, type, row) {
                    var rdate = new Date(data[3])
                        // console.log(formatTime(rdate));
                    return formatTime(rdate);
                }
            },
            {
                "targets": 4,
                "data": null,
                "render": function(data, type, row) {
                    var rdate = new Date(data[4])
                        // console.log(formatDate(rdate));
                    return formatDate(rdate);
                }
            },
            {
                "targets": 5,
                "data": null,
                "render": function(data, type, row) {
                    // console.log(data[5]);
                    var html = data[5] ? "<i class='fa fa-circle text-green'></i>" : "<i class='fa fa-circle text-red'></i>";
                    return html;
                }
            },
            {
                "targets": 6,
                "orderable": false,
                "data": null,
                "render": function(data, type, row) {
                    // console.log(data[5]);
                    if (data[5]) {
                        var reg = RegExp(/boss/);
                        if (data[1].length == 41 || reg.test(data[1])) {
                            var html = "<a href='javascript:void(0);' class='conn4ect443 btn btn-default btn-xs'><i class='far fa-arrow-alt-circle-right'></i> Mgmt</a>"
                            html += "<a href='javascript:void(0);' class='sshConnect btn btn-default btn-xs'><i class='fa fa-terminal'></i> SSH</a>"
                            return html;
                        } else {
                            var html = 'NotApplied';
                            return html;
                        }
                    } else {
                        var html = 'Unreachable';
                        return html;
                    }
                }
            },
        ],
    });


    $('#clientStatusModal').on('shown.bs.modal',
        function(e) {
            storename = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            cn = $(e.relatedTarget).parent().parent().children(".dtr-control").next().text();
            var thismodal = $('#clientStatusModal');
            thismodal.find('.modal-body').html("<p>storename: " + storename + "</p><p>cn: " + cn + "</p>");
            $(this).on('click', '.btn-primary', { 'filename': cn }, function(e) {
                var newstorename = thismodal.find('input').val();
                console.log("newstorename:" + newstorename);
                if (newstorename) {
                    $.post("service/clientstatus/update", { 'cn': cn, 'newstorename': newstorename }, function(result) {
                        console.log("服务器返回结果：" + result.result);
                        $('#tbclientstatus').DataTable().ajax.reload(); // reload table data
                        $('#clientStatusModal').modal('hide'); // hide modal
                    });
                }
            });

        });

    $("#clientStatusModal").on("hidden.bs.modal", function(e) { // remove the actual elements from the DOM when fully hidden
        $('#clientStatusModal').find("input[type=text], textarea").val("");
        $(this).find('form').trigger('reset');
    });


    $('#tunclientStatusModal').on('shown.bs.modal',
        function(e) {
            storename = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            cn = $(e.relatedTarget).parent().parent().children(".dtr-control").next().text();
            var thismodal = $('#tunclientStatusModal');
            thismodal.find('.modal-body').html("<p>storename: " + storename + "</p><p>cn: " + cn + "</p>");
            $(this).on('click', '.btn-primary', { 'filename': cn }, function(e) {
                var newstorename = thismodal.find('input').val();
                console.log("newstorename:" + newstorename);
                if (newstorename) {
                    $.post("service/tunclientstatus/update", { 'cn': cn, 'newstorename': newstorename }, function(result) {
                        console.log("服务器返回结果：" + result.result);
                        $('#tuntbclientstatus').DataTable().ajax.reload(); // reload table data
                        $('#tunclientStatusModal').modal('hide'); // hide modal
                    });
                }
            });
        });

    $("#tunclientStatusModal").on("hidden.bs.modal", function(e) { // remove the actual elements from the DOM when fully hidden
        $('#tunclientStatusModal').find("input[type=text], textarea").val("");
        $(this).find('form').trigger('reset');
    });


    // Port 443 connection
    $('#tbclientstatus tbody').on('click', '.conn4ect443', function(e) {
        var clientIp = $(this).parent().parent().children().eq(2).text();
        var cn = $(this).parent().parent().children().eq(1).text();
        // console.log(clientIp);
        var ipSliceList = clientIp.split('.')
            // console.log(ipSliceList);
        var toUrlpart = 'boss-0x';
        for (var i = 0; i < ipSliceList.length; i++) {
            var everyPart = parseInt(ipSliceList[i]).toString(16);
            // console.log("长度：" + everyPart.length);
            if (everyPart.length < 2) {
                everyPart = "0" + String(everyPart);
                // console.log("转化后：" + everyPart);
            }
            // console.log(parseInt(ipSliceList[i]).toString(16));
            toUrlpart = toUrlpart + everyPart;
        }
        // console.log(toUrlpart);
        var url = "/" + toUrlpart + "/";
        console.log("转化后：" + url);
        var openNewLink = window.open(url);
        openNewLink.focus();
    });

    // SSH connection
    // https://service.carel-remote.com/wssh/?hostname=xx&username=yy&password=str_base64_encoded&title=boss-a98bd3ba-cfc3-11ed-94a8-c400ad64f34a
    // https://service.carel-remote.com/wssh/?hostname=192.168.120.62&username=root&title=boss-a98bd3ba-cfc3-11ed-94a8-c400ad64f34a
    $('#tbclientstatus tbody').on('click', '.sshConnect', function(e) {
        var clientIp = $(this).parent().parent().children().eq(2).text();
        var cn = $(this).parent().parent().children().eq(1).text();
        var storename = $(this).parent().parent().children().eq(0).text();
        var url = "/wssh/" + "?hostname=" + clientIp;
        url = url + '&' + "username=root";
        url = url + "&title=" + storename;
        console.log("ssh url: " + url);
        var openNewLink = window.open(url);
        openNewLink.focus();
    });

    // Port 443 connection
    $('#tuntbclientstatus tbody').on('click', '.conn4ect443', function(e) {
        var clientIp = $(this).parent().parent().children().eq(2).text();
        var cn = $(this).parent().parent().children().eq(1).text();
        // console.log(clientIp);
        var ipSliceList = clientIp.split('.')
            // console.log(ipSliceList);
        var toUrlpart = 'boss-0x';
        for (var i = 0; i < ipSliceList.length; i++) {
            var everyPart = parseInt(ipSliceList[i]).toString(16);
            // console.log("长度：" + everyPart.length);
            if (everyPart.length < 2) {
                everyPart = "0" + String(everyPart);
                // console.log("转化后：" + everyPart);
            }
            // console.log(parseInt(ipSliceList[i]).toString(16));
            toUrlpart = toUrlpart + everyPart;
        }
        // console.log(toUrlpart);
        var url = "/" + toUrlpart + "/";
        console.log("转化后：" + url);
        var openNewLink = window.open(url);
        openNewLink.focus();
    });


    // SSH connection
    // https://service.carel-remote.com/wssh/?hostname=xx&username=yy&password=str_base64_encoded&title=boss-a98bd3ba-cfc3-11ed-94a8-c400ad64f34a
    // https://service.carel-remote.com/wssh/?hostname=192.168.120.62&username=root&title=boss-a98bd3ba-cfc3-11ed-94a8-c400ad64f34a
    $('#tuntbclientstatus tbody').on('click', '.sshConnect', function(e) {
        var clientIp = $(this).parent().parent().children().eq(2).text();
        var cn = $(this).parent().parent().children().eq(1).text();
        var storename = $(this).parent().parent().children().eq(0).text();
        var url = "/wssh/" + "?hostname=" + clientIp;
        url = url + '&' + "username=root";
        url = url + "&title=" + storename;
        console.log("ssh url: " + url);
        var openNewLink = window.open(url);
        openNewLink.focus();
    });

    // update the fname in the input 
    $(".custom-file > input").on("change", function() {
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
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        "buttons": ["excel", "colvis"],
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
            'url': "service/reqs/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        "columnDefs": [{
            "targets": 3,
            "data": null,
            "render": function(data, type, row) {
                var id = '"' + row.id + '"';
                var html = "<a href='javascript:void(0);'  class='reqDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#reqDelModal'  ><i class='fa fa-times'></i> Delete</a>"
                    // html += "<a href='javascript:void(0);'   onclick='deleteThisRowPapser(" + id + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
                html += "<a href='javascript:void(0);' class='reqDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
                return html;
            }
        }],
    });

    $("#tuntbreqfiles").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        "buttons": ["excel", "colvis"],
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
            'url': "service/tunreqs/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        "columnDefs": [{
            "targets": 3,
            "data": null,
            "render": function(data, type, row) {
                var id = '"' + row.id + '"';
                var html = "<a href='javascript:void(0);'  class='reqDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#tunreqDelModal'  ><i class='fa fa-times'></i> Delete</a>"
                    // html += "<a href='javascript:void(0);'   onclick='deleteThisRowPapser(" + id + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
                html += "<a href='javascript:void(0);' class='reqDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i> Download</a>"
                return html;
            }
        }],
    });

    $("#tbcertfiles").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        // "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
        "buttons": ["excel", "colvis"],
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
            'url': "service/certed/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        // datatable inline-button
        // https://datatables.net/reference/option/columnDefs
        "columnDefs": [{
            "targets": 3,
            "data": null,
            "render": function(data, type, row) {
                var id = '"' + row.id + '"';
                var html = "<a href='javascript:void(0);'  class='certDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#certDelModal'  ><i class='fa fa-times'></i> Delete</a>"
                    // html += "<a href='javascript:void(0);'   onclick='deleteCertByFilename(" + 99 + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
                html += "<a href='javascript:void(0);' class='certDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
                return html;
            }
        }],
    });

    $("#tuntbcertfiles").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        // "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
        "buttons": ["excel", "colvis"],
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
            'url': "service/tuncerted/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        // datatable inline-button
        // https://datatables.net/reference/option/columnDefs
        "columnDefs": [{
            "targets": 3,
            "data": null,
            "render": function(data, type, row) {
                var id = '"' + row.id + '"';
                var html = "<a href='javascript:void(0);'  class='certDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#tuncertDelModal'  ><i class='fa fa-times'></i> Delete</a>"
                    // html += "<a href='javascript:void(0);'   onclick='deleteCertByFilename(" + 99 + ")'  class='down btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
                html += "<a href='javascript:void(0);' class='certDownload btn btn-default btn-xs'><i class='fa fa-arrow-down'></i>Download</a>"
                return html;
            }
        }],
    });

    $("#tuntbgenericcertfiles").DataTable({
        // "dom": 'Blfrtip',
        "dom": '<"row"<"col"B><"col"f>>rt<"row"<"col"i><"col"p>>',
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        // "responsive": true, "lengthChange": true, "autoWidth": true,
        // "buttons": ["copy", "csv", "excel", "pdf", "print", "colvis"],
        "buttons": ["excel", "colvis"],
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
            'url': "service/tungenericcerted/list",
            'type': 'POST',
            'data': {},
            'dataType': 'json',
        },
        // datatable inline-button
        // https://datatables.net/reference/option/columnDefs
        "columnDefs": [{
            "targets": 3,
            "data": null,
            "render": function(data, type, row) {
                var id = '"' + row.id + '"';
                var html = "<a href='javascript:void(0);'  class='certDelete btn btn-danger btn-xs' data-toggle='modal' data-target='#tungenericcertDelModal'  ><i class='fa fa-times'></i> Delete</a>"
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
        function(e) {
            var reqFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            $(this).on('click', '.btn-danger', { 'filename': reqFileName }, function(e) {
                // alert("Deleted!!");
                $.post("service/reqs/delete", { 'filename': reqFileName }, function(result) {
                    // console.log(result)
                    $('#tbreqfiles').DataTable().ajax.reload(); // reload table data
                });
                $('#reqDelModal').modal('hide'); // hide modal
            });
        })

    $('#tunreqDelModal').on('show.bs.modal',
        function(e) {
            var reqFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            $(this).on('click', '.btn-danger', { 'filename': reqFileName }, function(e) {
                // alert("Deleted!!");
                $.post("service/tunreqs/delete", { 'filename': reqFileName }, function(result) {
                    // console.log(result)
                    $('#tuntbreqfiles').DataTable().ajax.reload(); // reload table data
                });
                $('#tunreqDelModal').modal('hide'); // hide modal
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
        function(e) {
            var certFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            $(this).on('click', '.btn-danger', { 'filename': certFileName }, function(e) {
                // alert("Deleted!!");
                $.post("service/certed/delete", { 'filename': certFileName }, function(result) {
                    // console.log(result)
                    $('#tbcertfiles').DataTable().ajax.reload();
                });
                $('#certDelModal').modal('hide'); // hide modal
            });
        })

    $('#tuncertDelModal').on('show.bs.modal',
        function(e) {
            var certFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            $(this).on('click', '.btn-danger', { 'filename': certFileName }, function(e) {
                // alert("Deleted!!");
                $.post("service/tuncerted/delete", { 'filename': certFileName }, function(result) {
                    // console.log(result)
                    $('#tuntbcertfiles').DataTable().ajax.reload();
                });
                $('#tuncertDelModal').modal('hide'); // hide modal
            });
        })

    $('#tungenericcertDelModal').on('show.bs.modal',
        function(e) {
            var certFileName = $(e.relatedTarget).parent().parent().children(".dtr-control").text();
            $(this).on('click', '.btn-danger', { 'filename': certFileName }, function(e) {
                // alert("Deleted!!");
                $.post("service/tungenericcerted/delete", { 'filename': certFileName }, function(result) {
                    // console.log(result)
                    $('#tuntbgenericcertfiles').DataTable().ajax.reload();
                });
                $('#tungenericcertDelModal').modal('hide'); // hide modal
            });
        })

    // req files download
    $('#tbreqfiles tbody').on('click', '.reqDownload', function() {
        var reqFileName = $(this).parent().parent().children(".dtr-control").text();
        //Set the File URL.
        var url = "service/reqs/dl/" + reqFileName;
        console.log(url);
        $.ajax({
            url: url,
            cache: false,
            xhr: function() {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
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
            success: function(data) {
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

    // tun req files download
    $('#tuntbreqfiles tbody').on('click', '.reqDownload', function() {
        var reqFileName = $(this).parent().parent().children(".dtr-control").text();
        //Set the File URL.
        var url = "service/tunreqs/dl/" + reqFileName;
        console.log(url);
        $.ajax({
            url: url,
            cache: false,
            xhr: function() {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
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
            success: function(data) {
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
    $('#tbcertfiles tbody').on('click', '.certDownload', function(e) {
        var certFileName = $(this).parent().parent().children(".dtr-control").text();
        e.preventDefault();
        var url = 'service/certed/dl/' + certFileName;
        console.log(url);
        window.location.href = url;
    });

    $('#tuntbcertfiles tbody').on('click', '.certDownload', function(e) {
        var certFileName = $(this).parent().parent().children(".dtr-control").text();
        e.preventDefault();
        var url = 'service/tuncerted/dl/' + certFileName;
        console.log(url);
        window.location.href = url;
    });

    $('#tuntbgenericcertfiles tbody').on('click', '.certDownload', function(e) {
        var certFileName = $(this).parent().parent().children(".dtr-control").text();
        e.preventDefault();
        var url = 'service/tungenericcerted/dl/' + certFileName;
        console.log(url);
        window.location.href = url;
    });

    // $('#tbcertfiles tbody').on('click', '.certDownload', function () {
    //   var certFileName = $(this).parent().parent().children(".dtr-control").text();
    //   //Set the File URL.
    //   var url = "service/reqs/dl/" + certFileName;
    //   console.log(url);
    //   $.ajax({
    //     url: url,
    //     cache: false,
    //     xhr: function () {
    //       var xhr = new XMLHttpRequest();
    //       xhr.onreadystatechange = function () {
    //         if (xhr.readyState == 2) {
    //           if (xhr.status == 200) {
    //             xhr.responseType = "blob";
    //           } else {
    //             xhr.responseType = "text";
    //           }
    //         }
    //       };
    //       return xhr;
    //     },
    //     success: function (data) {
    //       //Convert the Byte Data to BLOB object.
    //       var blob = new Blob([data], { type: "application/octet-stream" });

    //       //Check the Browser type and download the File.
    //       var isIE = false || !!document.documentMode;
    //       if (isIE) {
    //         window.navigator.msSaveBlob(blob, certFileName);
    //       } else {
    //         var url = window.URL || window.webkitURL;
    //         link = url.createObjectURL(blob);
    //         var a = $("<a />");
    //         a.attr("download", certFileName);
    //         a.attr("href", link);
    //         $("body").append(a);
    //         a[0].click();
    //         $("body").remove(a);
    //       }
    //     }
    //   });
    // });

});