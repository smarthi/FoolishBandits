from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import JSONResponse

import logging
import pandas as pd

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("bandits")

app = FastAPI()



@app.get("/healthcheck/", include_in_schema=True, status_code=200)
async def health_check():
    # respond with 200 and OK
    return Response(status_code=200, content="OK")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)