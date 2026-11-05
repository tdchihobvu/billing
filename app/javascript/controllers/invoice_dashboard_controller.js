
import { Controller } from "@hotwired/stimulus"
import {
  Chart,
  DoughnutController,
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
} from "chart.js"

Chart.register(
  DoughnutController,
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
)

export default class extends Controller {
  static targets = ["statusChart", "financialChart"]

  static values = {
    statuses: Object,
    financials: Array
  }

  connect() {
    this.renderStatusChart()
    this.renderFinancialChart()
  }

  disconnect() {
    this.statusChart?.destroy()
    this.financialChart?.destroy()
  }

  renderStatusChart() {
    if (!this.hasStatusChartTarget) return

    const statuses = this.statusesValue

    this.statusChart?.destroy()

    this.statusChart = new Chart(this.statusChartTarget, {
      type: "doughnut",
      data: {
        labels: [
          "Fully Paid",
          "Not Paid",
          "Partly Paid",
          "Overpaid",
          "Void",
          "Deleted"
        ],
        datasets: [{
          data: [
            statuses.fully_paid || 0,
            statuses.not_paid || 0,
            statuses.partly_paid || 0,
            statuses.overpaid || 0,
            statuses.void || 0,
            statuses.deleted || 0
          ],
          backgroundColor: [
            "#16a34a",
            "#ef4444",
            "#f59e0b",
            "#3b82f6",
            "#94a3b8",
            "#64748b"
          ],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "65%",
        plugins: {
          legend: {
            position: "bottom"
          }
        }
      }
    })
  }

  renderFinancialChart() {
    if (!this.hasFinancialChartTarget) return

    this.financialChart?.destroy()

    const financials = this.financialsValue

    this.financialChart = new Chart(this.financialChartTarget, {
      type: "bar",
      data: {
        labels: financials.map(item => item.currency),
        datasets: [
          {
            label: "Invoiced",
            data: financials.map(item => Number(item.total_invoiced)),
            backgroundColor: "#3b82f6"
          },
          {
            label: "Collected",
            data: financials.map(item => Number(item.total_paid)),
            backgroundColor: "#16a34a"
          },
          {
            label: "Outstanding",
            data: financials.map(item => Number(item.outstanding_balance)),
            backgroundColor: "#f59e0b"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: "bottom"
          }
        },
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    })
  }
}
