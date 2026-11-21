---
title: Heretical Framework reaches its first published pre-release
date: 2026-11-21 23:00:00 +0000
categories: [Workspace, Framework]
tags: [framework, nuget, woodpecker, dotnet, ci, packages, developer-tools]
source:
  repository: Heretical Development workspace
  publication: https://heretical-solutions.github.io/Heretical-Documentation/
  idempotency_key: framework-ci-publication-milestone-2026-11-21
editorial_approval:
  reviewer: BenevolentDrone
  approved_at: 2026-11-21 23:00:00 +0000
---

A reviewed workspace change has carried Heretical Framework from a collection of Unity
source modules to an independently packaged C# library suite with a working publication
path. The coordinated **`0.1.0-alpha.1` pre-release is now published on GitHub Packages**,
and a real consumer can restore it together with its first-party dependencies.

This is a meaningful engineering milestone, not a stable-release declaration.

## Independent packages instead of an umbrella assembly

The source audit rejected the old `Core` umbrella concept. Accepted engine-independent
modules now have their own projects, contracts, tests, dependency declarations, and
source provenance. Generation suffixes such as `V2` and `V3` are removed from target
module, project, namespace, and package identifiers while the original source paths and
hashes remain available in migration records.

The current suite contains **41 package projects**. Interface and implementation packages
remain separate, including asynchronous contract packages. Dependencies are explicit and
minimal: consumers restore only the declared package graph rather than inheriting the
Unity project's entire plugin pool. Unity-specific integration, DI adapters, and native
or media backends remain separately scoped work rather than accidental dependencies of
the engine-independent cores.

The resulting packages target `netstandard2.1` and `net8.0` and build with ordinary
`dotnet` commands. No Unity-generated project or `.meta` file is needed for the
engine-independent libraries.

## Validation through a real CI pipeline

Woodpecker's local desktop agent now runs an 18-step validation workflow for the suite.
The complete run passed **343 tests**, package production, provenance checks, and isolated
local package consumers. The publication scripts still use ordinary .NET restore, build,
test, and pack commands; Python is used for manifest, package, dependency-closure, and
provenance inspection.

The CI image contains the pinned .NET SDK and Python together. This was a deliberate
response to repeated per-step downloads, not a claim that every shared cache is forbidden.
An immutable toolchain image can be shared safely while each step still has its own
fresh writable layer and the normal CI workspace. Project dependencies still come from
committed lock files, and secrets remain outside the image.

## A coordinated pre-release with real consumers

The coordinated pre-release was published manually after validation. Its `.nuspec`
metadata records first-party NuGet dependencies, so a consumer does not need to reference
every module separately. The real-feed verification exercises both a package with a
dependency chain and the MVVM package, proving transitive restore from GitHub Packages.

The publication flow now documents:

- classic PAT scopes for publishing and reading;
- repository-scoped secrets restricted to manual pipelines and the CI image;
- explicit release-version and confirmation arguments;
- the actual GitHub API key and user-level NuGet configuration required for publication;
- a separate read-only credential for consumer verification;
- visibility decisions and manual-only obsolete-version review.

There is no automatic publication on merge, automatic latest-version selection, or
scheduled deletion of old versions. The next SemVer is selected deliberately, and
package versions and first-party dependency versions move together through a reviewed
release change.

## Documentation and next steps

The [Framework CI and publication quickstart](https://github.com/Heretical-Solutions/Heretical-Framework/blob/master/docs/ci-publication-quickstart.md)
records the current operator path, including agent setup, the absolute-path Woodpecker
CLI, publication, consumer verification, and the failure modes encountered during setup.
The [package versioning guide](https://github.com/Heretical-Solutions/Heretical-Framework/blob/master/docs/package-versioning.md)
explains coordinated SemVer bumps, exact/minimum/floating dependency constraints,
visibility, and manual retention review.

The next module candidate is SpacePartitioning, subject to its attribution and
completion-status review. Unity/UPM adapters, container-specific DI integrations, and
native/media backends remain separate scoped efforts. No stable compatibility promise,
Unity execution claim, or automatic release schedule is implied by this pre-release.
