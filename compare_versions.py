#!/usr/bin/env python3
"""
Fetch all Minecraft version JSONs and compare their schemas.
Usage: uv run compare_versions.py
"""

import json
import asyncio
from pathlib import Path
from collections import defaultdict
from typing import Dict, Set, Any
import httpx


async def fetch_json(client: httpx.AsyncClient, url: str) -> Dict[str, Any] | None:
    """Fetch JSON from a URL."""
    try:
        response = await client.get(url, timeout=30.0)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return None


def extract_schema(obj: Any, prefix: str = "") -> Set[str]:
    """Recursively extract all field paths from a JSON object."""
    fields = set()

    if isinstance(obj, dict):
        for key, value in obj.items():
            field_path = f"{prefix}.{key}" if prefix else key
            fields.add(f"{field_path} ({type(value).__name__})")

            # Recurse into nested objects
            if isinstance(value, (dict, list)):
                fields.update(extract_schema(value, field_path))

    elif isinstance(obj, list) and obj:
        # For arrays, analyze the first element to understand structure
        field_path = f"{prefix}[0]"
        first_item = obj[0]
        fields.add(f"{prefix}[] ({type(first_item).__name__})")

        if isinstance(first_item, (dict, list)):
            fields.update(extract_schema(first_item, f"{prefix}[]"))

    return fields


async def main():
    manifest_path = Path("Fixtures/version_manifest.json")

    if not manifest_path.exists():
        print(f"Error: {manifest_path} not found")
        return

    # Load the version manifest
    with open(manifest_path) as f:
        manifest = json.load(f)

    versions = manifest.get("versions", [])
    print(f"Found {len(versions)} versions in manifest")

    # Group versions by type
    versions_by_type = defaultdict(list)
    for v in versions:
        versions_by_type[v.get("type", "unknown")].append(v)

    print(f"Version types: {dict((k, len(v)) for k, v in versions_by_type.items())}")

    # Sample versions from each type to avoid overwhelming the API
    sample_versions = []
    for version_type, type_versions in versions_by_type.items():
        # Take first, middle, and last version of each type
        if len(type_versions) >= 3:
            sample_versions.extend([
                type_versions[0],
                type_versions[len(type_versions) // 2],
                type_versions[-1]
            ])
        else:
            sample_versions.extend(type_versions)

    print(f"\nSampling {len(sample_versions)} versions for detailed analysis...")

    # Fetch version details
    schemas = {}

    async with httpx.AsyncClient() as client:
        tasks = []
        for version in sample_versions:
            version_id = version.get("id")
            url = version.get("url")
            if url:
                tasks.append((version_id, fetch_json(client, url)))

        # Fetch in batches to avoid rate limiting
        batch_size = 10
        for i in range(0, len(tasks), batch_size):
            batch = tasks[i:i + batch_size]
            print(f"Fetching batch {i // batch_size + 1}/{(len(tasks) + batch_size - 1) // batch_size}...")

            results = await asyncio.gather(*[task for _, task in batch])

            for (version_id, _), result in zip(batch, results):
                if result:
                    schemas[version_id] = extract_schema(result)

            # Small delay between batches
            if i + batch_size < len(tasks):
                await asyncio.sleep(1)

    print(f"\nSuccessfully fetched {len(schemas)} version details")

    # Analyze schema differences
    all_fields = set()
    for fields in schemas.values():
        all_fields.update(fields)

    # Find which fields appear in which versions
    field_coverage = defaultdict(list)
    for version_id, fields in schemas.items():
        for field in all_fields:
            if field in fields:
                field_coverage[field].append(version_id)

    # Categorize fields
    universal_fields = []
    partial_fields = []
    rare_fields = []

    for field, versions_with_field in sorted(field_coverage.items()):
        coverage = len(versions_with_field) / len(schemas)
        if coverage == 1.0:
            universal_fields.append(field)
        elif coverage >= 0.5:
            partial_fields.append((field, versions_with_field))
        else:
            rare_fields.append((field, versions_with_field))

    # Output results
    print("\n" + "=" * 80)
    print("SCHEMA ANALYSIS RESULTS")
    print("=" * 80)

    print(f"\n📊 Total unique fields found: {len(all_fields)}")
    print(f"   - Universal fields (100% coverage): {len(universal_fields)}")
    print(f"   - Partial fields (50-99% coverage): {len(partial_fields)}")
    print(f"   - Rare fields (<50% coverage): {len(rare_fields)}")

    print("\n✅ UNIVERSAL FIELDS (present in all versions):")
    for field in sorted(universal_fields):
        print(f"   {field}")

    if partial_fields:
        print("\n⚠️  PARTIAL FIELDS (present in some versions):")
        for field, versions_with_field in partial_fields:
            coverage = len(versions_with_field) / len(schemas) * 100
            print(f"   {field}")
            print(f"      Coverage: {coverage:.1f}% ({len(versions_with_field)}/{len(schemas)} versions)")
            print(f"      Versions: {', '.join(versions_with_field[:5])}" +
                  (f"... (+{len(versions_with_field) - 5} more)" if len(versions_with_field) > 5 else ""))

    if rare_fields:
        print("\n🔍 RARE FIELDS (present in few versions):")
        for field, versions_with_field in rare_fields:
            coverage = len(versions_with_field) / len(schemas) * 100
            print(f"   {field}")
            print(f"      Coverage: {coverage:.1f}% ({len(versions_with_field)}/{len(schemas)} versions)")
            print(f"      Versions: {', '.join(versions_with_field)}")

    # Save detailed results to JSON
    output_path = Path("schema_comparison_results.json")
    with open(output_path, 'w') as f:
        json.dump({
            "summary": {
                "total_versions_analyzed": len(schemas),
                "total_unique_fields": len(all_fields),
                "universal_fields_count": len(universal_fields),
                "partial_fields_count": len(partial_fields),
                "rare_fields_count": len(rare_fields)
            },
            "universal_fields": sorted(universal_fields),
            "partial_fields": {
                field: {
                    "coverage_percent": len(versions) / len(schemas) * 100,
                    "versions": versions
                }
                for field, versions in partial_fields
            },
            "rare_fields": {
                field: {
                    "coverage_percent": len(versions) / len(schemas) * 100,
                    "versions": versions
                }
                for field, versions in rare_fields
            },
            "version_schemas": {
                version_id: sorted(list(fields))
                for version_id, fields in schemas.items()
            }
        }, f, indent=2)

    print(f"\n💾 Detailed results saved to: {output_path}")


if __name__ == "__main__":
    asyncio.run(main())
