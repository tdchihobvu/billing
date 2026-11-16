// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import "chartkick/chart.js"

import "./src/jquery"
import "jquery-ui"
import "./jquery.easing.min"
import "./jquery.easing.compatibility"

import DataTable from "datatables.net-bs5"
window.bootstrap = bootstrap;
window.DataTable = DataTable;

import "./sidebar"
import "./tables"
import "./quick_search"
import "./live_search"
import "trix"
import "@rails/actiontext"
