FROM --platform=amd64 python:3.10-slim

WORKDIR /usr/src/app

COPY requirements.txt ./

#CPU versions of torch distributed only on custom repo
#See https://pytorch.org/get-started/locally/
RUN pip install --no-cache-dir \
        --extra-index-url https://download.pytorch.org/whl/cpu \
        -r requirements.txt 

COPY app.py .

USER nobody

CMD [ "python", "./app.py" ]
