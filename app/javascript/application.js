// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import "chartkick/chart.js"

import "./src/jquery"
import "jquery-ui"
import "./sb-admin-2.min"
import "./jquery.easing.min"
import "./jquery.easing.compatibility"

import DataTable from "datatables.net-bs5"
Chartkick.addAdapter(Chart);

window.bootstrap = bootstrap;
window.DataTable = DataTable();

$(function() {
	console.log("hello world")
})

import "trix"
import "@rails/actiontext"
