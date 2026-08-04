export const sampleCode = `package app

data Point {
  x = 0
  y = 0
}

fun add(a, b) {
  return a + b
}

fun main() {
  let mut p = Point(1, 2)
  p.x = 3
  let total = add(p.x, p.y)
}`

interface Feature {
  title: string
  quote: string
  desc: string
  href: string
}

export interface HomeContent {
  title: string
  nav: {
    gettingStarted: string
    docs: string
  }
  hero: { title: string; subtitle: string; quote: string; note: string }
  features: { title: string; items: Feature[] }
  quickstart: {
    title: string
    steps: { cmd: string; desc: string }[]
    codeTitle: string
  }
  philosophy: { title: string; quote: string; note: string }
  footer: { license: string }
}

export const home: HomeContent = {
  title: 'Tao 语言',
  nav: {
    gettingStarted: '快速上手',
    docs: '文档',
  },
  hero: {
    title: 'Tao 语言',
    subtitle: 'Tao is a tiny language implemented in Ruby',
    quote: '道生一，一生二，二生三，三生萬物。',
    note: '字面量六，由是生萬物，少而不窮；築于 Ruby，而異于 Ruby。',
  },
  features: {
    title: '特性',
    items: [
      {
        title: '極簡',
        quote: '「為學日益，為道日損。損之又損，以至于無為。」',
        desc: '關鍵字止于十七，語法即表達，不加于物。',
        href: '/docs/syntax',
      },
      {
        title: '錯以值傳',
        quote: '「天下莫柔弱于水，而攻堅強者莫之能勝。」',
        desc: '不舉異常，Go 之風：try 見錯即返，let val, err = expr 手解之。',
        href: '/docs/control-flow',
      },
      {
        title: '水之道',
        quote: '「上善若水。水善利萬物而不爭。」',
        desc: '管道一往而流：expr |> f(a, b) 即 f(a, b, expr)。',
        href: '/docs/functions',
      },
      {
        title: '有無相生',
        quote: '「三十輻共一轂，當其無，有車之用。」',
        desc: '惟 None、False 為假；0、""、[] 為真。?? 惟察 None，無則有依。',
        href: '/docs/values',
      },
      {
        title: '統一言美',
        quote: '「天得一以清，地得一以寧，萬物得一以生。」',
        desc: '構物與呼函同形：data Nothing {} 亦以 Nothing() 呼之。',
        href: '/docs/data',
      },
    ],
  },
  quickstart: {
    title: '快速上手',
    steps: [
      { cmd: 'gem install taoism', desc: '安装 gem' },
      { cmd: 'tao hello.tao', desc: '以脚本运行' },
      { cmd: 'taoism', desc: '交互式控制台' },
    ],
    codeTitle: 'hello.tao',
  },
  philosophy: {
    title: '哲思',
    quote: '「有之以為利，無之以為用。」',
    note: 'Tao 以「道」名，設計之哲，依《道德經》而行。',
  },
  footer: { license: 'Taoism 遵循 1-clause BSD License。' },
}
