//
//  AboutView.swift
//  fedi-archive-tool
//
//  Created by Wolfe on 23.06.24.
//

import SwiftUI

struct AboutView: View {
    @State var dependencyPopupShown = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "??"
                
                Text("""
            Version \(version)
            
            An app for reading Fediverse archives, tested and compatible with Mastodon
            
            Developed as a public service by [ish.works](https://ish.works/)
            
            Fedi Archive is Open Source Software — all of the code is in the public domain and [available on GitHub](https://github.com/dvorakroth/fedi-archive-tool). No information is sent anywhere by the app, and all archives are stored locally, as detailed in the [privacy policy](https://ish.works/fedi-archive-privacy.html).
            
            Making and publishing Fedi Archive (as well as keeping myself alive) requires effort and money, so if you found this app useful, it would be really cool if you could consider [leaving a tip](https://ko-fi.com/ish00). Thank you! 🤟🏻
            
            Fedi Archive uses plenty of open-source libraries, [listed here](fake://jkl/).
            
            Trans rights are human rights! 🏳️‍⚧️
            """)
                .frame(maxWidth: .infinity)
                    .environment(\.openURL, OpenURLAction { url in
                        if url.absoluteString == "fake://jkl/" {
                            dependencyPopupShown = true
                            return .discarded
                        } else {
                            return .systemAction
                        }
                    })
                    .sheet(isPresented: $dependencyPopupShown) {
                        LibrariesView(showModal: $dependencyPopupShown)
                    }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}

struct LibrariesView: View {
    @Binding var showModal: Bool
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    
                    Button() {
                        showModal = false
                    } label: {
                        Image(systemName: "x.square")
                        Text("Dismiss")
                    }
                    .padding(.bottom, 5)
                    
                    Spacer()
                }
                
                Text("").frame(maxWidth: .infinity)
                Text("BlurHash").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2018 Wolt Enterprises

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                
                Text("DataCompression").font(.headline)
                Text("""
                This product includes software developed by Markus Wanke and published under the Apache-2.0 license. For more details see [here](https://github.com/mw99/DataCompression/blob/master/LICENSE).
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                Text("SwiftUI-LazyPager").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2022 Brian Floersch

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                Text("SQLite.swift").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2014-2015 Stephen Celis (\\<stephen[]()@stephencelis.com\\>)

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                Text("SwiftSoup").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2016 Nabil Chatbi

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                Text("Tarscape").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2021 Keith Blount

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                
                Additionally, Tarscape builds on and makes use of code from other projects, [listed here](https://github.com/kayembi/Tarscape/blob/main/LICENSE).
                """).font(.custom("Helvetica", size: 8))
                
                Text("").frame(maxWidth: .infinity)
                Text("ZIPFoundation").font(.headline)
                Text("""
                MIT License

                Copyright (c) 2017-2024 Thomas Zoechling (https[]()://www.peakstep.com)

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """).font(.custom("Helvetica", size: 8))
            }
        }.padding(20)
    }
}

#Preview {
    AboutView()
}
