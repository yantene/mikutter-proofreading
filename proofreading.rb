# -*- coding: utf-8 -*-

Plugin.create(:proofreading) do
  require 'net/http'
  require 'uri'
  require 'rexml/document'

  settings '推敲支援' do
    input 'Yahoo! App. ID.', :yahoo_appid
    multiselect '表記・表現の間違いや不適切な表現に関する指摘', :proofreading_ind do
      option 1, '誤変換'
      option 2, '誤用'
      option 3, '使用注意'
      option 4, '不快語'
      option 5, '機種依存または拡張文字'
      option 6, '外国地名'
      option 7, '固有名詞'
      option 8, '人名'
      option 9, 'ら抜き'
    end
    multiselect 'わかりやすい表記にするための指摘', :proofreading_ind do
      option 10, '当て字'
      option 11, '表外漢字あり'
      option 12, '用字'
    end
    multiselect '文章をよりよくするための指摘', :proofreading_ind do
      option 13, '用語言い換え'
      option 14, '二重否定'
      option 15, '助詞不足の可能性あり'
      option 16, '冗長表現'
      option 17, '略語'
    end
  end

  command(:proofreading,
          name: '投稿ボックスのテキストの校正チェック',
          condition: ->(_) { true },
          visible: false,
          role: :postbox) do |opt|
    sentence = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
    activity :system, get_indications(sentence).join("\n")
  end

  ProofreaderURI = URI.parse('http://jlp.yahooapis.jp/KouseiService/V1/kousei').freeze

  def request(sentence)
    Net::HTTP.start(ProofreaderURI.host, ProofreaderURI.port) do |http|
      header = {
        'Host' => ProofreaderURI.host,
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
      body = [
        "appid=#{UserConfig[:yahoo_appid]}",
        "no_filter=#{((1..17).to_a - UserConfig[:proofreading_ind]).join(',')}",
        "sentence=#{URI.encode(sentence)}"
      ].join('&')
      http.post(ProofreaderURI.path, body, header)
    end
  end

  def get_indications(sentence)
    xml = REXML::Document.new(request(sentence).body)
    xml.get_elements('/ResultSet/Result').map do |ind|
      ind.elements.map { |e| [e.name.to_sym, e.text] }.to_h
    end
  end
end
