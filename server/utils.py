"""A module containing helper functions."""
import io
from pathlib import Path
import subprocess
import zipfile

JOB_EXT_MAP = {
    "pmc": ["res"],
}


def run_imitator_pmc(
        imi_filepath: str,
        imiprop_filepath: str,
        output_path: str,
) -> None:
    """A helper function running in the background the PMC imitator process.

    Args:
        imi_filepath (str): The imi filepath.
        imiprop_filepath (str): The imiprop filepath.
        output_path (str): The output path.
    """
    subprocess.run(
        [
            "/imitator/bin/imitator",
            imi_filepath,
            imiprop_filepath,
            "-output-prefix",
            output_path,
        ],
        check=False,
    )


def map_job_type_to_result_extensions(job_type: str) -> list | None:
    """A helper function mapping job type to list of result files.

    Args:
        job_type (str): The type of the job.

    Returns:
        list | None: The list of the result files.
    """
    return JOB_EXT_MAP.get(job_type)


def check_job_completness(job_dir: str, job_type: str) -> bool:
    """A helper function checking if the job has been finished.

    Args:
        job_dir (str): The job output path.
        job_type (str): The type of the job.

    Returns:
        bool: True if the job has been finished.
    """
    job_type_extensions = JOB_EXT_MAP[job_type]

    for ext in job_type_extensions:
        if len(list(Path(job_dir).glob(f"*.{ext}"))) == 0:
            return False

    return True


def get_job_result_files(job_dir: str, job_type: str) -> list | None:
    """A helper function returning paths to job result files.

    Args:
        job_dir (str): The job output path.
        job_type (str): The type of the job.

    Returns:
        list: The list of the result files.
    """
    job_type_extensions = JOB_EXT_MAP[job_type]
    result_files = []

    for ext in job_type_extensions:
        result_files += Path(job_dir).glob(f"*.{ext}")

    if len(result_files) == len(job_type_extensions):
        return result_files

    return None


def get_result_zip_file(result_files: list) -> io.BytesIO:
    """A helper function returning in-memory ZIP with job result files.

    Args:
        result_files (list): The result files list.

    Returns:
        io.BytesIO: The in-memory ZIP file.
    """
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as f:
        for fp in result_files:
            f.write(fp, arcname=fp.name)
    buf.seek(0)

    return buf
