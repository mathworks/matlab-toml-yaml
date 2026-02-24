# #18: Benchmark performance and scaling for large YAML/TOML files

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-16  

## Description

Most configuration files are very small. But I've seen cases where users will put thousands of simulation parameters, constants, and metadata in a large configuration file (usually JSON).

It would be good to do some early benchmarking to make sure that the design can scale linearly as the number of keys or array elements grows very large. We could also draft a performance optimization plan that includes vectorization, incremental (on-demand) parsing, memory/storage optimization, etc.

## Comments

### Comment by michellehirsch on 2026-01-16

Good idea. We currently document a limitation/risk that this is not tested or designed for large files. I'd be surprised to see yaml or toml files much bigger than a few thousand lines. But we should stress test.

### Comment by michellehirsch on 2026-01-16

Performance tests added: [de3e270](https://github.com/michellehirsch/matlab-toml-yaml/commit/de3e2700dcd5957ceae3a5c2ccb7f5eed2c6fd9a)
