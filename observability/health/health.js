const httpDuration = "http_server_request_duration_seconds";
const busMessages = "gc_bus_messages_total";
const busProcess = "gc_bus_process_duration_milliseconds";
const busInflight = "gc_bus_inflight";
const operations = "gc_operation_duration_milliseconds";
const database = "db_client_operation_duration_seconds";

const services = [
  { label: "Gateway", name: "Gateway" },
  { label: "Platform", name: "Platform MS" },
  { label: "WoW", name: "WorldOfWarcraft MS" },
  { label: "LoL", name: "LeagueOfLegends MS" },
];

const pinned = ["Users.Touch", "user.identity.changed"];

const text = (id, value, bad) => {
  const node = document.getElementById(id);
  node.textContent = value;
  node.classList.toggle("bad", Boolean(bad));
};

const rate = (metric, extra = "") => `sum(rate(${metric}_count${extra}[1m]))`;
const errors = (metric) => `sum(rate(${metric}_count{http_response_status_code=~"5.."}[1m]))`;
const quantile = (metric, q, extra = "") =>
  `histogram_quantile(${q}, sum by (le) (rate(${metric}_bucket${extra}[5m])))`;

async function query(expression) {
  const response = await fetch("/prom/api/v1/query?query=" + encodeURIComponent(expression));
  if (!response.ok) throw new Error("Prometheus " + response.status);
  const body = await response.json();
  if (body.status !== "success") throw new Error("Prometheus query failed");
  return body.data.result;
}

function numberOf(sample) {
  if (!sample) return null;
  const value = Number(sample.value[1]);
  return Number.isFinite(value) ? value : null;
}

function scalar(result) {
  return numberOf(result[0]);
}

function byLabel(result, label) {
  const values = new Map();
  for (const sample of result) {
    const key = sample.metric[label];
    const value = numberOf(sample);
    if (key && value !== null) values.set(key, value);
  }
  return values;
}

const formatRate = (value) => (value === null ? "—" : value.toFixed(1));
const formatMs = (secondsOrMs, alreadyMs) => {
  if (secondsOrMs === null) return "—";
  const ms = alreadyMs ? secondsOrMs : secondsOrMs * 1000;
  return (ms < 10 ? ms.toFixed(1) : Math.round(ms).toString()) + " ms";
};
const formatPercent = (value) => (value === null ? "—" : (value * 100).toFixed(1) + " %");
const formatCount = (value) => (value === null ? "—" : Math.round(value).toString());
const formatPerMin = (perSecond) => (perSecond === null ? "—" : (perSecond * 60).toFixed(0));

function renderServices(latency, errorRate) {
  const body = document.getElementById("services");
  body.replaceChildren();
  for (const service of services) {
    const row = document.createElement("tr");
    const name = document.createElement("td");
    const p95 = document.createElement("td");
    const errorsCell = document.createElement("td");
    name.textContent = service.label;
    const latencyMs = latency.get(service.name);
    const ratio = errorRate.get(service.name);
    p95.textContent = formatMs(latencyMs ?? null, false);
    errorsCell.textContent = formatPercent(ratio ?? null);
    if (ratio > 0) errorsCell.classList.add("bad");
    row.append(name, p95, errorsCell);
    body.append(row);
  }
}

function renderOperations(perSecond) {
  const list = document.getElementById("operations");
  list.replaceChildren();
  const names = [...pinned];
  const extras = [...perSecond.keys()]
    .filter((name) => !pinned.includes(name))
    .sort((left, right) => perSecond.get(right) - perSecond.get(left))
    .slice(0, 8);
  for (const name of names.concat(extras)) {
    const row = document.createElement("div");
    const label = document.createElement("dt");
    const value = document.createElement("dd");
    label.textContent = name + " / min";
    value.textContent = formatPerMin(perSecond.get(name) ?? null);
    row.append(label, value);
    list.append(row);
  }
}

async function refresh() {
  const [
    httpRate,
    httpErrorRate,
    httpP50,
    httpP95,
    httpP99,
    busRate,
    busP95,
    busErrors,
    inflight,
    serviceP95,
    serviceErrors,
    serviceTotal,
    dbRate,
    dbP95,
    operationRate,
  ] = await Promise.all([
    query(rate(httpDuration)),
    query(errors(httpDuration)),
    query(quantile(httpDuration, 0.5)),
    query(quantile(httpDuration, 0.95)),
    query(quantile(httpDuration, 0.99)),
    query(`sum(rate(${busMessages}[1m]))`),
    query(quantile(busProcess, 0.95)),
    query(`sum(increase(${busMessages}{result="error"}[1m]))`),
    query(`sum(${busInflight})`),
    query(`histogram_quantile(0.95, sum by (service_name, le) (rate(${httpDuration}_bucket[5m])))`),
    query(`sum by (service_name) (rate(${httpDuration}_count{http_response_status_code=~"5.."}[1m]))`),
    query(`sum by (service_name) (rate(${httpDuration}_count[1m]))`),
    query(rate(database)),
    query(quantile(database, 0.95)),
    query(`sum by (operation) (rate(${operations}_count[1m]))`),
  ]);

  const httpTotal = scalar(httpRate);
  const httpFailed = scalar(httpErrorRate);
  text("http-rate", formatRate(httpTotal));
  text("http-errors", formatPercent(httpTotal ? (httpFailed ?? 0) / httpTotal : null), httpFailed > 0);
  text("http-p50", formatMs(scalar(httpP50), false));
  text("http-p95", formatMs(scalar(httpP95), false));
  text("http-p99", formatMs(scalar(httpP99), false));

  const failedMessages = scalar(busErrors);
  text("bus-rate", formatRate(scalar(busRate)));
  text("bus-p95", formatMs(scalar(busP95), true));
  text("bus-errors", formatCount(failedMessages), failedMessages > 0);
  text("bus-inflight", formatCount(scalar(inflight)));

  const totals = byLabel(serviceTotal, "service_name");
  const failed = byLabel(serviceErrors, "service_name");
  const ratios = new Map();
  for (const [name, total] of totals) {
    ratios.set(name, total > 0 ? (failed.get(name) ?? 0) / total : null);
  }
  renderServices(byLabel(serviceP95, "service_name"), ratios);
  renderOperations(byLabel(operationRate, "operation"));

  text("db-rate", formatRate(scalar(dbRate)));
  text("db-p95", formatMs(scalar(dbP95), false));
  document.getElementById("updated").textContent = "Updated " + new Date().toLocaleTimeString();
}

renderServices(new Map(), new Map());
renderOperations(new Map());

async function tick() {
  try {
    await refresh();
  } catch (error) {
    document.getElementById("updated").textContent = error.message;
  }
}

tick();
setInterval(tick, 5000);
