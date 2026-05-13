  lifecycle {
    ignore_changes = [
      # --- Forces replacement ---
      # O GCP retorna use_ip_aliases e os range names de forma divergente
      # após a criação, forçando replacement desnecessário.
      config[0].node_config[0].ip_allocation_policy[0].use_ip_aliases,
      config[0].node_config[0].ip_allocation_policy[0].cluster_secondary_range_name,
      config[0].node_config[0].ip_allocation_policy[0].services_secondary_range_name,

      # O GCP resolve aliases de imagem para versões exatas
      # (ex: "composer-3-airflow-2.9" -> "composer-3-airflow-2.9.3-build.54").
      # Ignorar evita replacement a cada plan sem mudança real de versão.
      config[0].software_config[0].image_version,

      # --- Campos populados automaticamente pelo GCP ---
      # Rede interna
      config[0].node_config[0].composer_internal_ipv4_cidr_block,
      config[0].node_config[0].composer_network_attachment,
      config[0].node_config[0].disk_size_gb,
      config[0].node_config[0].enable_ip_masq_agent,
      config[0].node_config[0].machine_type,
      config[0].node_config[0].oauth_scopes,
      config[0].node_config[0].tags,
      config[0].node_config[0].zone,
      # Ambiente
      config[0].node_count,
      config[0].resilience_mode,
      config[0].web_server_config,
      config[0].web_server_network_access_control,
      config[0].database_config,
      config[0].storage_config,
      # Software
      config[0].software_config[0].scheduler_count,
      config[0].software_config[0].web_server_plugins_mode,
      config[0].software_config[0].python_version,
      config[0].software_config[0].cloud_data_lineage_integration,
      # Workloads
      config[0].workloads_config[0].dag_processor,
    ]
