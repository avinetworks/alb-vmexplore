
resource "null_resource" "download_ubuntu_focal" {
  provisioner "local-exec" {
    command = "curl -s -o /tmp/$(basename ${var.content_library.source_url_ubuntu_focal}) ${var.content_library.source_url_ubuntu_focal}"
  }
}

resource "null_resource" "download_avi" {
  provisioner "local-exec" {
    command = "wget -q -O /tmp/controller_tf_ako_demo.ova \"${var.avi_controller_url}\""
  }
}

resource "vsphere_content_library" "library" {
  name            = "${var.content_library.basename}${random_string.id.result}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "file_ubuntu_focal" {
  depends_on = [null_resource.download_ubuntu_focal]
  name        = basename(var.content_library.source_url_ubuntu_focal)
  library_id  = vsphere_content_library.library.id
  file_url = "/tmp/${basename(var.content_library.source_url_ubuntu_focal)}"
}

resource "vsphere_content_library_item" "file_avi" {
  depends_on = [null_resource.download_avi]
  name        = "controller_tf_ako_demo.ova"
  library_id  = vsphere_content_library.library.id
  file_url = "/tmp/controller_tf_ako_demo.ova"
}

resource "null_resource" "remove_download_ubuntu" {
  depends_on = [vsphere_content_library_item.file_avi, vsphere_content_library_item.file_ubuntu_focal]
  provisioner "local-exec" {
    command = "rm -f /tmp/$(basename ${var.content_library.source_url_ubuntu_focal}); rm -f /tmp/controller_tf_ako_demo.ova"
  }
}