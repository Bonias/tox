require 'test_helper'
require 'benchmark'
require 'stringio'

class ToxTest < Minitest::Test
  def test_empty
    test_case(
      %{
        <name/>
      },
      nil
    ) do
      el(:name, text)
    end
  end

  def test_empty_nested
    test_case(
      %{
        <name>
          <first/>
          <last>Ross</last>
        </name>
      },
      { first: nil, last: 'Ross' }
    ) do
      el(:name, {
        first: el(:first, text),
        last: el(:last, text),
      })
    end
  end

  def test_blank
    test_case(
      %{
        <name></name>
      },
      ''
    ) do
      el(:name, text)
    end
  end

  def test_simple_el
    test_case(
      %{
        <name>Mike</name>
      },
      "Mike"
    ) do
      el(:name, text)
    end
  end

  def test_special_chars
    test_case(
      %{
        <name>你好世界</name>
      },
      "你好世界"
    ) do
      el(:name, text)
    end
  end

  def test_io
    test_case_parse(
      StringIO.new(%{
        <name>Mike</name>
      }),
      "Mike"
    ) do
      el(:name, text)
    end
  end

  def test_simple_el_wrapped
    test_case(
      %{
        <name>Mike</name>
      },
      {
        firstname: "Mike"
      }
    ) do
      {
        firstname: el(:name, text)
      }
    end
  end

  def test_simple_el_double_wrapped
    test_case(
      %{
        <name>Mike</name>
      },
      {
        firstname: {
          value: "Mike"
        }
      }
    ) do
      {
        firstname: el(:name, {
          value: text
        })
      }
    end
  end

  def test_deep_text
    test_case(
      %{
        <t1><t2><t3>deep</t3></t2></t1>
      },
      "deep"
    ) do
      el(:t1, el(:t2, el(:t3, text)))
    end
  end

  def test_children
    test_case(
      %{
        <name>
          <first>Mike</first>
          <last>Ross</last>
        </name>
      },
      {
        f: 'Mike',
        l: 'Ross'
      }
    ) do
      el(:name, {
        f: el(:first, text),
        l: el(:last, text)
      })
    end
  end

  def test_collect
    test_case(
      %{
        <names>
          <name>Mike Ross</name>
          <name>Harvey Specter</name>
        </names>
      },
      ['Mike Ross', 'Harvey Specter']
    ) do
      el(:names, mel(:name, text))
    end
  end

  def test_collect_multi
    test_case(
      %{
        <col>
          <names>
            <name>Mike Ross</name>
            <name>Harvey Specter</name>
          </names>
          <ages>
            <age>25</age>
            <age>35</age>
          </ages>
        </col>
      },
      {
        names: ['Mike Ross', 'Harvey Specter'],
        ages: ['25', '35']
      }
    ) do
      el(:col, {
        names: el(:names, mel(:name, text)),
        ages: el(:ages, mel(:age, text))
      })
    end
  end

  def test_collect_mixed
    test_case(
      %{
        <col>
          <name>Mike Ross</name>
          <name>Harvey Specter</name>
          <age>25</age>
          <age>35</age>
        </col>
      },
      {
        names: ['Mike Ross', 'Harvey Specter'],
        ages: ['25', '35']
      }
    ) do
      el(:col, {
        names: mel(:name, text),
        ages: mel(:age, text)
      })
    end
  end

  def test_complex
    test_case(
      %{
        <profile>
          <first>Mike</first>
          <last>Ross</last>
          <friends>
            <friend>
              <first>Harvey</first>
              <last>Specter</last>
            </friend>
            <friend>
              <first>Louis</first>
              <last>Litt</last>
            </friend>
          </friends>
        </profile>
      },
      {
        f: 'Mike',
        l: 'Ross',
        friends: [
          {
            f: 'Harvey',
            l: 'Specter'
          },
          {
            f: 'Louis',
            l: 'Litt'
          }
        ]
      }
    ) do
      el(:profile, {
        f: el(:first, text),
        l: el(:last, text),
        friends: el(:friends, mel(:friend, {
          f: el(:first, text),
          l: el(:last, text)
        }))
      })
    end
  end

  def test_partial
    test_case_asym(
      %{
        <name>
          <first a='true'>Mike</first>
          <ignored/>
          <deep>
            <ignored b='4'>true</ignored>
          </deep>
          <last>Ross</last>
        </name>
      },
      %{
        <name>
          <first>Mike</first>
        </name>
      },
      {
        f: 'Mike'
      }
    ) do
      el(:name, {
        f: el(:first, text)
      })
    end
  end

  def test_complex_scope
    test_case_asym(
      %{
        <profile>
          <first>Mike</first>
          <last>Ross</last>
          <friends>
            <friend>
              <first>Harvey</first>
              <last>Specter</last>
            </friend>
            <friend>
              <first>Louis</first>
              <last>Litt</last>
            </friend>
          </friends>
        </profile>
      },
      %{
        <profile>
          <first>Mike</first>
          <last>Ross</last>
          <friends>
            <friend>
              <first>Harvey</first>
            </friend>
            <friend>
              <first>Louis</first>
            </friend>
          </friends>
        </profile>
      },
      {
        f: 'Mike',
        l: 'Ross',
        friend_firstnames: ['Harvey', 'Louis']
      }
    ) do
      el(:profile, {
        f: el(:first, text),
        l: el(:last, text),
        friend_firstnames: el(:friends, mel(:friend, el(:first, text)))
      })
    end
  end

  def test_simple_attr
    test_case(
      %{
        <name age="25">Mike</name>
      },
      {
        name: 'Mike',
        age: '25'
      }
    ) do
      el(:name, {
        name: text,
        age: at(:age)
      })
    end
  end

  def test_single_attr
    test_case(
      %{
        <name age="25"/>
      },
      '25'
    ) do
      el(:name, at(:age))
    end
  end

  def test_complex_attr
    test_case(
      %{
        <profile>
          <first>Mike</first>
          <last>Ross</last>
          <friends>
            <friend age="40">
              <first>Harvey</first>
              <last>Specter</last>
            </friend>
            <friend>
              <first>Louis</first>
              <last>Litt</last>
            </friend>
          </friends>
        </profile>
      },
      {
        f: 'Mike',
        l: 'Ross',
        friends: [
          {
            f: 'Harvey',
            l: 'Specter',
            age: '40'
          },
          {
            f: 'Louis',
            l: 'Litt'
          }
        ]
      }
    ) do
      el(:profile, {
        f: el(:first, text),
        l: el(:last, text),
        friends: el(:friends, mel(:friend, {
          f: el(:first, text),
          l: el(:last, text),
          age: at(:age)
        }))
      })
    end
  end

  def test_namespaces
    test_case(
      %{
        <name xmlns="a" xmlns:b="c">Mike</name>
      },
      {
        name: 'Mike'
      }
    ) do
      el(:name, {
        name: text
      }, {
        nil => 'a',
        'b' => 'c'
      })
    end
  end

  GOOGLE_BATCH_XML = File.read(
    File.expand_path('../cases/google_batch.xml', __FILE__)
  )

  GOOGLE_BATCH_TPL = Tox::Template.new(Tox::Template::DSL.module_eval(
    File.read(File.expand_path('../cases/google_batch.rb', __FILE__))
  ))

  def test_performance
    if ENV['PERFORMANCE']
      value = GOOGLE_BATCH_TPL.parse(GOOGLE_BATCH_XML)

      puts
      Benchmark.bm do |x|
        x.report do
          10_000.times do
            GOOGLE_BATCH_TPL.parse(GOOGLE_BATCH_XML)
          end
        end

        x.report do
          10_000.times do
            GOOGLE_BATCH_TPL.render(value)
          end
        end
      end
    end
  end

  private

  def test_case(xml, value, &template)
    test_case_asym(xml, xml, value, &template)
  end

  def test_case_asym(xml_parse, xml_render, value, &template)
    test_case_parse(xml_parse, value, &template)
    test_case_render(xml_render, value, &template)
  end

  def test_case_parse(xml, value, &template)
    template = Tox::Template.dsl(&template)
    assert_equal(value, template.parse(xml, false))
  end

  def test_case_render(xml, value, &template)
    template = Tox::Template.dsl(&template)
    assert_equal(
      scrub(xml),
      scrub(template.render(value))
    )
  end

  def scrub(str)
    str.gsub(/\n */, '')
  end
end
