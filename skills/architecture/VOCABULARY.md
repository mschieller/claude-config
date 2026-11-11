# Deep-module vocabulary

Use these terms exactly in reports and decisions. Do not substitute "component", "service", "API" or "boundary".

## Terms

- **Module.** Anything with an interface and an implementation: a function, a class, a package or a slice across tiers.
- **Interface.** Everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration and performance characteristics.
- **Implementation.** The code inside a module.
- **Depth.** How much behavior a caller or test can use per unit of interface it has to learn. A module is deep when a lot of behavior sits behind a small interface, and shallow when the interface is nearly as complex as the implementation.
- **Seam.** A place where behavior can change without editing that place. The location where a module's interface lives.
- **Adapter.** A concrete thing that satisfies an interface at a seam. It names a role, not what is inside.
- **Leverage.** What callers get from depth: more capability per unit of interface learned.
- **Locality.** What maintainers get from depth: change, bugs and verification concentrate in one place.

## Principles

- Depth belongs to the interface, not the implementation. A deep module can be built from small internal parts, as long as they are not part of the interface.
- The deletion test. Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across many callers, it earns its keep.
- The interface is the test surface. Callers and tests cross the same seam. A test that has to reach past the interface means the module has the wrong shape.
- One adapter is a hypothetical seam. Two adapters is a real one. Add a seam only when something varies across it, usually production and test.

## Dependency categories

Classify a candidate's dependencies. The category decides how the deepened module is tested.

1. **In-process.** Pure computation and in-memory state. Merge the modules and test through the new interface. No adapter.
2. **Local stand-in.** A dependency with a local test version, such as PGlite or a test container for Postgres, or an in-memory filesystem. Test with the stand-in. The seam stays internal.
3. **Remote and owned.** Your own services over the network. Define a port at the seam, with an HTTP or gRPC adapter in production and an in-memory adapter in tests.
4. **External.** Third-party services. Inject them as a port and use a fake adapter in tests.

## Testing a deepened module

- Write tests at the new interface. They assert on observable outcomes, not internal state.
- Delete the old tests on the shallow modules once the new tests cover the behavior. Replace them, do not layer new tests on top.
- A test that must change when the implementation changes is testing past the interface.

## Designing for testability

- Accept dependencies instead of creating them inside the module.
- Return results instead of producing side effects where the caller can apply them.
- Keep the interface small: fewer entry points and fewer parameters mean fewer tests and simpler setup.
