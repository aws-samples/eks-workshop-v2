FROM python:3.8-slim-buster

ENV TARGET_FILE="/terraform/helm_versions.tf.json"

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

CMD ["python3", "./check_helm_charts.py"]