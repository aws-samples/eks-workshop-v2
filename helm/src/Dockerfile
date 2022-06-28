FROM python:3.8-slim-buster

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

CMD ["python3", "./check_helm_charts.py", "-c", "/config/charts.yaml", "/terraform/helm_versions.tf.json"]