import kfp
from google_cloud_pipeline_components.v1.bigquery import BigqueryQueryJobOp
from google_cloud_pipeline_components.v1.automl.training_job import AutoMLTabularTrainingJobRunOp
from google_cloud_pipeline_components.v1.dataset import TabularDatasetCreateOp
from google_cloud_pipeline_components.v1.endpoint import EndpointCreateOp, ModelDeployOp

project_id = "vlba-2024-mpd-group-6"
pipeline_root_path = "gs://vlba-g6-ml-pipeline-bucket"

def create_and_import_dataset_tabular_bigquery_sample(
    display_name: str,
    project: str,
    bigquery_source: str,
):
    ds_op = TabularDatasetCreateOp(
        display_name=display_name,
        bq_source=bigquery_source,
        project=project,
    )
    return ds_op

@kfp.dsl.pipeline(
    name="g6_regr_model_forecast_pipeline",
    pipeline_root=pipeline_root_path)
def pipeline(project_id: str):
    ds_op = create_and_import_dataset_tabular_bigquery_sample(
        "Profit_prod_data",
        project_id,
        "bq://vlba-2024-mpd-group-6.mpd_g6_data.ZZMPD_Past_Profit_CYMP_Model"
    )
    
    training_job_run_op = AutoMLTabularTrainingJobRunOp(
        project=project_id,
        display_name="train_regression_model",
        optimization_prediction_type="regression",
        dataset=ds_op.outputs["dataset"],
        model_display_name="Profit_Regr_Forecast_Model",
        target_column="monthly_profit",
        budget_milli_node_hours=1000,
    )
    
    create_endpoint_op = EndpointCreateOp(
        project=project_id,
        display_name="Profit_pipeline_endpoint",
    )
    
    model_deploy_op = ModelDeployOp(
        model=training_job_run_op.outputs["model"],
        endpoint=create_endpoint_op.outputs['endpoint'],
        dedicated_resources_machine_type="n1-standard-16",
        dedicated_resources_min_replica_count=1,
        dedicated_resources_max_replica_count=1,
    )

from kfp import compiler
compiler.Compiler().compile(
    pipeline_func=pipeline,
    package_path='g6_Profit_regr_model_pipeline.yaml'
)
