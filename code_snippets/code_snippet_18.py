import google.cloud.aiplatform as aip


project_id = "vlba-2024-mpd-group-6"
PROJECT_REGION = "europe-west1"
pipeline_root_path = "gs://vlba-g6-ml-pipeline-bucket/" 

aip.init(
    project=project_id,
    location=PROJECT_REGION,
)

job = aip.PipelineJob(
    display_name="g6_regr_Profit_pipeline",
    template_path="g6_Profit_regr_model_pipeline.yaml",
    pipeline_root=pipeline_root_path,
    parameter_values={
        'project_id': project_id
    }
)

job.submit()