"""A main module of the server app."""
from pathlib import Path
import uuid
from typing import Any

from flask import Flask, jsonify, request, send_file

import utils

UPLOAD_DIR = "./input"
OUTPUT_DIR = "./output"

app = Flask(__name__)
job_types: dict = {}


def _job_exists(job_id: str) -> bool:
    job_dir = Path(OUTPUT_DIR) / job_id

    if not job_types.get(job_id) or not job_dir.exists():
        return False

    return True


@app.post("/pmc")
def pmc() -> tuple:
    """An endpoint for basic Parametric Model Checking task."""
    if "imi_file" not in request.files and "imiprop_file" not in request.files:
        return jsonify(
            {
                "error": "Missing 'imi_file' or/and 'imiprop_file'.",
            }
        ), 400

    imi_file = request.files.get("imi_file")
    imiprop_file = request.files.get("imiprop_file")

    if not imi_file or not imiprop_file:
        return jsonify(
            {
                "error": "'imi_file' or/and 'imiprop_file' not provided.",
            }
        ), 400

    job_id = job_id = str(uuid.uuid4())
    input_dir = Path(UPLOAD_DIR) / job_id
    output_dir = Path(OUTPUT_DIR) / job_id / "result"
    input_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    imi_filepath = input_dir / "file.imi"
    imiprop_filepath = input_dir / "file.imiprop"

    imi_file.save(imi_filepath)
    imiprop_file.save(imiprop_filepath)

    job_types[job_id] = "pmc"

    utils.run_imitator_pmc(
        str(imi_filepath),
        str(imiprop_filepath),
        str(output_dir),
    )

    return jsonify({"job_id": job_id}), 200


@app.get("/tasks/<job_id>/status")
def job_status(job_id: str) -> tuple:
    """An endpoint checking current status of the task."""
    if not _job_exists(job_id):
        return jsonify({"error": "Task not found."}), 404

    job_finished = utils.check_job_completness(
        str(Path(OUTPUT_DIR) / job_id),
        job_types[job_id],
    )

    return jsonify({"finished": job_finished}), 200


@app.get("/tasks/<job_id>/result")
def job_result(job_id: str) -> Any:
    """An endpoint returning task results in ZIP file."""
    if not _job_exists(job_id):
        return jsonify({"error": "Task not found."}), 404

    job_dir = str(Path(OUTPUT_DIR) / job_id)
    job_type = job_types[job_id]

    if not utils.check_job_completness(job_dir, job_type):
        return jsonify({"error": "Task in progress."}), 400

    job_result_files = utils.get_job_result_files(
        job_dir,
        job_type
    )

    if not job_result_files:
        return jsonify(
            {"error": "Not all files have been produced by process."},
        ), 500

    zip_file = utils.get_result_zip_file(job_result_files)

    return send_file(
        zip_file,
        mimetype="application/zip",
        as_attachment=True,
        download_name="result.zip",
        max_age=0
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
