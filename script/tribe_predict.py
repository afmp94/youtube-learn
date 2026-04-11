#!/usr/bin/env python3
"""
TRIBE v2 Brain Prediction Bridge for YouTube Learn's Virality Lab.

Runs TRIBE v2 inference on text/video/audio input, maps vertex activations
to HCP brain regions, renders brain surface images, and outputs structured JSON.

Usage:
  python script/tribe_predict.py --text "content here" --output-dir /tmp/tribe_xxx
  python script/tribe_predict.py --video /path/to/video.mp4 --output-dir /tmp/tribe_xxx
  python script/tribe_predict.py --text-file /path/to/file.txt --output-dir /tmp/tribe_xxx
"""

import argparse
import json
import logging
import os
import sys
import tempfile
import warnings
from pathlib import Path

# Suppress all warnings to stderr, keep stdout clean for JSON
warnings.filterwarnings("ignore")
logging.basicConfig(stream=sys.stderr, level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

# Must set before any matplotlib import
import matplotlib
matplotlib.use("Agg")

import numpy as np

# ── HCP Region → Content Insight Mapping ──────────────────────────────────────

REGION_TO_CLUSTER = {
    # Visual Processing → hook_power
    "Primary Visual Cortex (V1)": "visual_processing",
    "Early Visual Cortex": "visual_processing",
    "Dorsal Stream Visual Cortex": "visual_processing",
    "Ventral Stream Visual Cortex": "visual_processing",
    "MT+ Complex and Neighboring Visual Areas": "visual_processing",

    # Language Network → storytelling
    "Inferior Frontal Cortex": "language_network",
    "Lateral Temporal Cortex": "language_network",
    "Temporo-Parieto-Occipital Junction": "language_network",

    # Emotion Circuit → emotional_resonance
    "Anterior Cingulate and Medial Prefrontal Cortex": "emotion_circuit",
    "Insular and Frontal Opercular Cortex": "emotion_circuit",
    "Medial Temporal Cortex": "emotion_circuit",

    # Reward & Novelty → novelty
    "Orbital and Polar Frontal Cortex": "reward_novelty",
    "DorsoLateral Prefrontal Cortex": "reward_novelty",

    # Social Cognition → shareability
    "Posterior Cingulate Cortex": "social_cognition",
    "Inferior Parietal Cortex": "social_cognition",
    "Superior Parietal Cortex": "social_cognition",

    # Auditory Processing → practical_value (engagement)
    "Early Auditory Cortex": "auditory_processing",
    "Auditory Association Cortex": "auditory_processing",
    "Posterior Opercular Cortex": "auditory_processing",

    # Motor (less relevant, but mapped)
    "Somatosensory and Motor Cortex": "motor",
    "Premotor Cortex": "motor",
    "Paracentral Lobular and Mid Cingulate Cortex": "motor",
}

CLUSTER_INFO = {
    "visual_processing": {
        "label": "Visual Impact",
        "dimension": "hook_power",
        "insight_template": "Visual cortex activation at {score}% suggests {level} attention-capture potential",
    },
    "language_network": {
        "label": "Language Processing",
        "dimension": "storytelling",
        "insight_template": "Language network engagement at {score}% indicates {level} narrative comprehension",
    },
    "emotion_circuit": {
        "label": "Emotional Response",
        "dimension": "emotional_resonance",
        "insight_template": "Limbic activation at {score}% suggests {level} emotional resonance",
    },
    "reward_novelty": {
        "label": "Novelty & Reward",
        "dimension": "novelty",
        "insight_template": "Prefrontal engagement at {score}% indicates {level} novelty processing",
    },
    "social_cognition": {
        "label": "Social Cognition",
        "dimension": "shareability",
        "insight_template": "Social cognition circuits at {score}% suggest {level} social sharing impulse",
    },
    "auditory_processing": {
        "label": "Auditory Engagement",
        "dimension": "practical_value",
        "insight_template": "Auditory cortex activation at {score}% indicates {level} auditory engagement",
    },
}


def score_level(score: int) -> str:
    if score >= 75:
        return "strong"
    elif score >= 50:
        return "moderate"
    elif score >= 25:
        return "weak"
    return "minimal"


def load_model(cache_folder: str):
    """Load TRIBE v2 model from HuggingFace."""
    logger.info("Loading TRIBE v2 model...")
    import torch
    from tribev2 import TribeModel

    model = TribeModel.from_pretrained("facebook/tribev2", cache_folder=cache_folder)

    # Override device from 'cuda' to 'mps' or 'cpu' on non-CUDA systems
    if not torch.cuda.is_available():
        device = "mps" if torch.backends.mps.is_available() else "cpu"
        logger.info(f"No CUDA — overriding extractors to device={device}")
        data = model.data
        for feat_name in ["text_feature", "audio_feature"]:
            feat = getattr(data, feat_name, None)
            if feat and hasattr(feat, "device"):
                feat.device = device

    logger.info("Model loaded.")
    return model


def run_inference(model, text=None, text_file=None, video=None, audio=None):
    """Run TRIBE v2 inference and return predictions + segments."""
    if text:
        # Write text to temp file for TTS conversion
        tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False)
        tmp.write(text)
        tmp.close()
        logger.info("Converting text to speech and running inference...")
        df = model.get_events_dataframe(text_path=tmp.name)
        os.unlink(tmp.name)
    elif text_file:
        logger.info(f"Processing text file: {text_file}")
        df = model.get_events_dataframe(text_path=text_file)
    elif video:
        logger.info(f"Processing video: {video}")
        df = model.get_events_dataframe(video_path=video)
    elif audio:
        logger.info(f"Processing audio: {audio}")
        df = model.get_events_dataframe(audio_path=audio)
    else:
        raise ValueError("No input provided")

    preds, segments = model.predict(events=df)
    logger.info(f"Predictions shape: {preds.shape}")
    return preds, segments


def compute_region_activations(preds: np.ndarray) -> dict:
    """Map raw vertex predictions to named brain regions using HCP parcellation."""
    from tribev2.utils import get_hcp_labels

    # Average across timesteps
    mean_activation = preds.mean(axis=0)

    # Normalize to 0-100 scale
    # Use robust normalization (clip outliers at 1st/99th percentile)
    p1, p99 = np.percentile(mean_activation, [1, 99])
    if p99 > p1:
        normalized = (mean_activation - p1) / (p99 - p1)
        normalized = np.clip(normalized, 0, 1) * 100
    else:
        normalized = np.full_like(mean_activation, 50.0)

    # Get HCP labels (combined = 22 named regions)
    label_to_vertices = get_hcp_labels(mesh="fsaverage5", combine=True, hemi="both")

    region_activations = {}
    for name, vertices in label_to_vertices.items():
        if name == "???":
            continue
        if len(vertices) > 0:
            region_activations[name] = float(np.mean(normalized[vertices]))

    return region_activations


def compute_cluster_scores(region_activations: dict) -> dict:
    """Aggregate region activations into functional clusters."""
    cluster_scores = {}

    for cluster_id, info in CLUSTER_INFO.items():
        regions = [r for r, c in REGION_TO_CLUSTER.items() if c == cluster_id]
        scores = [region_activations[r] for r in regions if r in region_activations]
        if scores:
            score = int(round(np.mean(scores)))
        else:
            score = 0

        cluster_scores[cluster_id] = {
            "score": score,
            "label": info["label"],
            "regions": regions,
            "region_scores": {r: round(region_activations.get(r, 0), 1) for r in regions},
        }

    return cluster_scores


def compute_virality_correlations(cluster_scores: dict) -> dict:
    """Map brain cluster activations to virality dimension insights."""
    correlations = {}

    for cluster_id, cluster in cluster_scores.items():
        info = CLUSTER_INFO[cluster_id]
        dimension = info["dimension"]
        score = cluster["score"]
        level = score_level(score)

        insight = info["insight_template"].format(score=score, level=level)

        correlations[dimension] = {
            "brain_score": score,
            "cluster": cluster_id,
            "supporting_regions": cluster["regions"][:3],
            "insight": insight,
        }

    return correlations


def compute_temporal_summary(preds: np.ndarray) -> dict:
    """Compute temporal activation timeline."""
    # Mean activation per timestep (across all vertices)
    timeline = preds.mean(axis=1)

    # Normalize to 0-100
    t_min, t_max = timeline.min(), timeline.max()
    if t_max > t_min:
        timeline_norm = ((timeline - t_min) / (t_max - t_min) * 100).tolist()
    else:
        timeline_norm = [50.0] * len(timeline)

    peak_idx = int(np.argmax(timeline))

    return {
        "n_timesteps": len(timeline),
        "peak_timestep": peak_idx,
        "peak_activation": round(float(timeline_norm[peak_idx]), 1),
        "activation_timeline": [round(v, 1) for v in timeline_norm],
    }


def render_brain_images(preds: np.ndarray, output_dir: str) -> dict:
    """Render brain surface activation images using nilearn (headless-compatible)."""
    try:
        import matplotlib.pyplot as plt
        from nilearn import datasets, plotting

        fsaverage = datasets.fetch_surf_fsaverage(mesh="fsaverage5")
        mean_activation = preds.mean(axis=0)

        # fsaverage5 has 10242 vertices per hemisphere, TRIBE outputs 20484 total
        n_hemi = mean_activation.shape[0] // 2
        left_data = mean_activation[:n_hemi]
        right_data = mean_activation[n_hemi:]

        # Normalize to robust range
        combined = np.concatenate([left_data, right_data])
        p1, p99 = np.percentile(combined, [2, 98])
        threshold = max(p1, 0.0)  # nilearn requires non-negative threshold

        views_config = [
            ("left", "lateral", "left", left_data, fsaverage["pial_left"], fsaverage["sulc_left"]),
            ("right", "lateral", "right", right_data, fsaverage["pial_right"], fsaverage["sulc_right"]),
            ("medial", "medial", "left", left_data, fsaverage["pial_left"], fsaverage["sulc_left"]),
            ("dorsal", "dorsal", "left", left_data, fsaverage["pial_left"], fsaverage["sulc_left"]),
        ]

        image_files = {}

        for view_name, view_type, hemi, data, mesh, bg_map in views_config:
            try:
                fig = plt.figure(figsize=(6, 5), facecolor="#0d0d18")
                ax = fig.add_subplot(111, projection="3d")
                plotting.plot_surf_stat_map(
                    mesh,
                    stat_map=data,
                    hemi=hemi,
                    view=view_type,
                    colorbar=False,
                    bg_map=bg_map,
                    cmap="hot",
                    vmax=p99,
                    threshold=threshold,
                    figure=fig,
                    axes=ax,
                )
                filename = f"brain_{view_name}.png"
                filepath = os.path.join(output_dir, filename)
                fig.savefig(
                    filepath, dpi=150, bbox_inches="tight",
                    facecolor="#0d0d18", edgecolor="none", transparent=False,
                )
                image_files[view_name] = filename
                logger.info(f"Rendered {filename}")
            except Exception as e:
                logger.warning(f"Failed to render {view_name}: {e}")
            finally:
                plt.close("all")

        return image_files

    except Exception as e:
        logger.warning(f"Brain image rendering failed: {e}")
        return {}


def main():
    parser = argparse.ArgumentParser(description="TRIBE v2 Brain Prediction Bridge")
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--text", help="Text content to analyze")
    input_group.add_argument("--text-file", help="Path to text file")
    input_group.add_argument("--video", help="Path to video file")
    input_group.add_argument("--audio", help="Path to audio file")

    parser.add_argument("--output-dir", required=True, help="Directory for output images")
    parser.add_argument("--cache-folder", default="/Users/afmp/Projects/tribev2/cache",
                       help="TRIBE v2 model cache folder")
    parser.add_argument("--skip-images", action="store_true",
                       help="Skip brain image rendering")

    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    try:
        # 1. Load model
        model = load_model(args.cache_folder)

        # 2. Run inference
        preds, segments = run_inference(
            model,
            text=args.text,
            text_file=args.text_file,
            video=args.video,
            audio=args.audio,
        )

        # 3. Compute region activations
        region_activations = compute_region_activations(preds)

        # 4. Compute cluster scores
        cluster_scores = compute_cluster_scores(region_activations)

        # 5. Compute virality correlations
        virality_correlations = compute_virality_correlations(cluster_scores)

        # 6. Compute temporal summary
        temporal_summary = compute_temporal_summary(preds)

        # 7. Render brain images
        brain_images = {}
        if not args.skip_images:
            brain_images = render_brain_images(preds, args.output_dir)

        # 8. Top regions by activation
        sorted_regions = sorted(region_activations.items(), key=lambda x: x[1], reverse=True)
        top_regions = [name for name, _ in sorted_regions[:6]]

        # Output JSON to stdout
        result = {
            "status": "success",
            "n_timesteps": int(preds.shape[0]),
            "region_activations": {k: round(v, 1) for k, v in region_activations.items()},
            "region_clusters": cluster_scores,
            "virality_correlations": virality_correlations,
            "temporal_summary": temporal_summary,
            "top_regions": top_regions,
            "brain_images": brain_images,
        }

        print(json.dumps(result))

    except Exception as e:
        error_result = {"status": "error", "error": str(e)}
        print(json.dumps(error_result))
        sys.exit(1)


if __name__ == "__main__":
    main()
