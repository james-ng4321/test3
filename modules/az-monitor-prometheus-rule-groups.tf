# ---------------------------------------------------------------------------
# Azure Managed Prometheus - Recommended Recording Rule Groups
#
# The community "Kubernetes / Compute Resources" Grafana dashboards query
# pre-aggregated recording-rule metrics (e.g. cluster:node_cpu:ratio_rate5m,
# node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate,
# namespace_cpu:kube_pod_container_resource_requests:sum). Azure Managed
# Prometheus does NOT create these rules automatically - without them the CPU
# / memory panels show "No data" even though raw metrics are being scraped.
#
# These are Microsoft's recommended Node + Kubernetes recording rule groups
# (the same ones the portal deploys when you enable Managed Prometheus).
# See: https://learn.microsoft.com/azure/azure-monitor/essentials/prometheus-rule-groups
#
# Created per AKS cluster that has: enable_prometheus = true + monitor_workspace_name.
#
# NOTE: cluster_name is intentionally omitted. Each Azure Monitor Workspace here
# backs a single cluster, and omitting it makes the rules evaluate over all
# series in the workspace while preserving the original `cluster` label in the
# output - which guarantees the dashboard's {cluster="$cluster"} filter matches
# regardless of the label's casing. Add cluster_name only if you attach multiple
# clusters to the same workspace.
# ---------------------------------------------------------------------------

locals {
  # AKS clusters that ship Prometheus metrics to an Azure Monitor Workspace.
  prometheus_recording_clusters = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_prometheus, false) && aks.monitor_workspace_name != null
  }

  # Node Recording Rules (Linux) - node-exporter derived aggregates.
  node_recording_rules = [
    {
      record     = "instance:node_num_cpu:sum"
      expression = <<-EOT
        count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})
      EOT
    },
    {
      record     = "instance:node_cpu_utilisation:rate5m"
      expression = <<-EOT
        1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))
      EOT
    },
    {
      record     = "instance:node_load1_per_cpu:ratio"
      expression = <<-EOT
        (  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})
      EOT
    },
    {
      record     = "instance:node_memory_utilisation:ratio"
      expression = <<-EOT
        1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})
      EOT
    },
    {
      record     = "instance:node_vmstat_pgmajfault:rate5m"
      expression = <<-EOT
        rate(node_vmstat_pgmajfault{job="node"}[5m])
      EOT
    },
    {
      record     = "instance_device:node_disk_io_time_seconds:rate5m"
      expression = <<-EOT
        rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])
      EOT
    },
    {
      record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
      expression = <<-EOT
        rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])
      EOT
    },
    {
      record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
      expression = <<-EOT
        sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))
      EOT
    },
    {
      record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
      expression = <<-EOT
        sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))
      EOT
    },
    {
      record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
      expression = <<-EOT
        sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))
      EOT
    },
    {
      record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
      expression = <<-EOT
        sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))
      EOT
    },
  ]

  # Kubernetes Recording Rules - cadvisor + kube-state-metrics derived aggregates.
  kubernetes_recording_rules = [
    {
      record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
      expression = <<-EOT
        sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job="cadvisor", image!=""}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=""}))
      EOT
      labels = {}
    },
    {
      record     = "node_namespace_pod_container:container_memory_working_set_bytes"
      expression = <<-EOT
        container_memory_working_set_bytes{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
      EOT
      labels = {}
    },
    {
      record     = "node_namespace_pod_container:container_memory_rss"
      expression = <<-EOT
        container_memory_rss{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
      EOT
      labels = {}
    },
    {
      record     = "node_namespace_pod_container:container_memory_cache"
      expression = <<-EOT
        container_memory_cache{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
      EOT
      labels = {}
    },
    {
      record     = "node_namespace_pod_container:container_memory_swap"
      expression = <<-EOT
        container_memory_swap{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
      EOT
      labels = {}
    },
    {
      record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
      expression = <<-EOT
        kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
      EOT
      labels = {}
    },
    {
      record     = "namespace_memory:kube_pod_container_resource_requests:sum"
      expression = <<-EOT
        sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
      EOT
      labels = {}
    },
    {
      record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
      expression = <<-EOT
        kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
      EOT
      labels = {}
    },
    {
      record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
      expression = <<-EOT
        sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
      EOT
      labels = {}
    },
    {
      record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
      expression = <<-EOT
        kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
      EOT
      labels = {}
    },
    {
      record     = "namespace_memory:kube_pod_container_resource_limits:sum"
      expression = <<-EOT
        sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
      EOT
      labels = {}
    },
    {
      record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
      expression = <<-EOT
        kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~"Pending|Running"} == 1) )
      EOT
      labels = {}
    },
    {
      record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
      expression = <<-EOT
        sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
      EOT
      labels = {}
    },
    {
      record     = "namespace_workload_pod:kube_pod_owner:relabel"
      expression = <<-EOT
        max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job="kube-state-metrics", owner_kind="ReplicaSet"},      "replicaset", "$1", "owner_name", "(.*)"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job="kube-state-metrics"}      )    ),    "workload", "$1", "owner_name", "(.*)"  ))
      EOT
      labels = { workload_type = "deployment" }
    },
    {
      record     = "namespace_workload_pod:kube_pod_owner:relabel"
      expression = <<-EOT
        max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="DaemonSet"},    "workload", "$1", "owner_name", "(.*)"  ))
      EOT
      labels = { workload_type = "daemonset" }
    },
    {
      record     = "namespace_workload_pod:kube_pod_owner:relabel"
      expression = <<-EOT
        max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="StatefulSet"},    "workload", "$1", "owner_name", "(.*)"  ))
      EOT
      labels = { workload_type = "statefulset" }
    },
    {
      record     = "namespace_workload_pod:kube_pod_owner:relabel"
      expression = <<-EOT
        max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="Job"},    "workload", "$1", "owner_name", "(.*)"  ))
      EOT
      labels = { workload_type = "job" }
    },
    {
      record     = ":node_memory_MemAvailable_bytes:sum"
      expression = <<-EOT
        sum(  node_memory_MemAvailable_bytes{job="node"} or  (    node_memory_Buffers_bytes{job="node"} +    node_memory_Cached_bytes{job="node"} +    node_memory_MemFree_bytes{job="node"} +    node_memory_Slab_bytes{job="node"}  )) by (cluster)
      EOT
      labels = {}
    },
    {
      record     = "cluster:node_cpu:ratio_rate5m"
      expression = <<-EOT
        sum(rate(node_cpu_seconds_total{job="node",mode!="idle",mode!="iowait",mode!="steal"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job="node"}) by (cluster, instance, cpu)) by (cluster)
      EOT
      labels = {}
    },
  ]
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node_recording" {
  for_each = local.prometheus_recording_clusters

  name                = "NodeRecordingRulesRuleGroup-${each.value.name}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  description         = "Node Recording Rules RuleGroup"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.main[each.value.monitor_workspace_name].id]

  dynamic "rule" {
    for_each = local.node_recording_rules
    content {
      enabled    = true
      record     = rule.value.record
      expression = trimspace(rule.value.expression)
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_monitor_workspace.main,
    azurerm_monitor_data_collection_rule_association.prometheus
  ]
}

resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes_recording" {
  for_each = local.prometheus_recording_clusters

  name                = "KubernetesRecordingRulesRuleGroup-${each.value.name}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  description         = "Kubernetes Recording Rules RuleGroup"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.main[each.value.monitor_workspace_name].id]

  dynamic "rule" {
    for_each = local.kubernetes_recording_rules
    content {
      enabled    = true
      record     = rule.value.record
      expression = trimspace(rule.value.expression)
      labels     = length(rule.value.labels) > 0 ? rule.value.labels : null
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_monitor_workspace.main,
    azurerm_monitor_data_collection_rule_association.prometheus
  ]
}
