# tiny_run_mcp.py
from fastmcp import FastMCP
from datetime import date
from uuid import uuid4

mcp = FastMCP("TinyRun")

runs = [
    {
        "id": "r1",
        "date": "2026-04-25",
        "km": 5.0,
        "min": 27,
        "type": "easy",
    },
    {
        "id": "r2",
        "date": "2026-04-27",
        "km": 8.0,
        "min": 42,
        "type": "tempo",
    },
]


def pace(km: float, minutes: float) -> float:
    return round(minutes / km, 2)


@mcp.tool
def list_runs() -> list[dict]:
    """List all runs."""
    return runs


@mcp.tool
def add_run(km: float, minutes: float, run_type: str = "easy") -> dict:
    """Add a run."""
    run = {
        "id": uuid4().hex[:6],
        "date": date.today().isoformat(),
        "km": km,
        "min": minutes,
        "type": run_type,
    }
    runs.append(run)
    return run


@mcp.tool
def summary() -> dict:
    """Summarize runs."""
    total_km = sum(r["km"] for r in runs)
    total_min = sum(r["min"] for r in runs)

    return {
        "runs": len(runs),
        "km": round(total_km, 1),
        "min": round(total_min, 1),
        "pace": pace(total_km, total_min) if total_km else None,
    }


@mcp.tool
def best_run() -> dict:
    """Return fastest run."""
    return min(runs, key=lambda r: pace(r["km"], r["min"]))


if __name__ == "__main__":
    mcp.run()