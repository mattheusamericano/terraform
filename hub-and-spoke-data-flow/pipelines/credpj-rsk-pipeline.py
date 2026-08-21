# Vertex AI Pipeline - credpj-rsk-pipeline
from kfp import dsl
from kfp import compiler

@dsl.component
def train_model():
    print("Training custom model credpj-rsk-pipeline...")

@dsl.pipeline(
    name='credpj-rsk-pipeline',
    description='Pipeline to train the model inside credpj'
)
def pipeline():
    train_model()

if __name__ == '__main__':
    compiler.Compiler().compile(pipeline_func=pipeline, package_path='credpj-rsk-pipeline.json')
