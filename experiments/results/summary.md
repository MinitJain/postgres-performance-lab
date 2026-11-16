| scenario | scan | sort? | heap | buffers | median exec (n=20) |
|---|---|---|---|---|---|
| 1-no-index | Seq Scan | yes | - | Buffers: shared hit=544 | 2.521 ms |
| 2-index | Bitmap Heap Scan | yes | Heap Blocks: exact=541 | Buffers: shared hit=544 | 0.460 ms |
| 2b-index-ssd-cost | Index Scan | no | - | Buffers: shared hit=548 | 0.369 ms |
| 3-index-no-bitmap | Seq Scan | yes | - | Buffers: shared hit=544 | 2.559 ms |
| 3b-forced-index-scan | Index Scan | no | - | Buffers: shared hit=548 | 0.362 ms |
| 4-clustered | Bitmap Heap Scan | yes | Heap Blocks: exact=6 | Buffers: shared hit=9 | 0.146 ms |
| 5-covering-index | Index Only Scan | no | Heap Fetches: 0 | Buffers: shared hit=1 | 0.095 ms |
| 6-covering-no-vacuum | Bitmap Heap Scan | yes | Heap Blocks: exact=541 | Buffers: shared hit=544 | 0.550 ms |
