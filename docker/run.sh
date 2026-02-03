#!/bin/bash
# Helper script for Godot Docker commands

cd "$(dirname "$0")"

case "${1:-help}" in
  build)
    echo "Building Docker image..."
    docker compose build
    ;;
  test)
    echo "Running tests..."
    docker compose run --rm test
    ;;
  validate)
    echo "Validating project..."
    docker compose run --rm validate
    ;;
  shell)
    echo "Opening shell in container..."
    docker compose run --rm godot bash
    ;;
  godot)
    shift
    echo "Running: godot $@"
    docker compose run --rm godot godot --headless "$@"
    ;;
  import)
    echo "Importing project resources..."
    docker compose run --rm godot godot --headless --import
    ;;
  help|*)
    echo "Usage: ./run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  build     Build the Docker image"
    echo "  test      Run all tests"
    echo "  validate  Validate project (import and check errors)"
    echo "  import    Import/reimport project resources"
    echo "  shell     Open bash shell in container"
    echo "  godot     Run arbitrary godot command (e.g., ./run.sh godot --version)"
    echo "  help      Show this help"
    ;;
esac
