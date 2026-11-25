# Dữ liệu tham chiếu của bộ máy luật T2

| File | Nội dung | Nguồn, giấy phép | Dựng lại |
|---|---|---|---|
| `airports.tsv` | Mã IATA sân bay → mã nước, múi giờ IANA, thành phố (tiếng Anh). ~7.900 dòng, 260 KB (82 KB nén) | [mwgg/Airports](https://github.com/mwgg/Airports), MIT; múi giờ chỉnh theo tzdata (`zone.tab`, `tzdata.zi`) | `python3 -I tool/build_airports.py airports.json > data/airports.tsv` |

App đóng gói các file này làm asset; bản cập nhật sau này đi cùng gói dữ liệu qua CDN có chữ ký (ADR về gói dữ liệu theo locale).
Tên thành phố theo ngôn ngữ khác ("Hà Nội", "東京") chưa có: T2 nhận diện sân bay qua mã IATA in trên vé.

## Ghi công

```
The MIT License (MIT)

Copyright (c) 2014 mwgg

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
