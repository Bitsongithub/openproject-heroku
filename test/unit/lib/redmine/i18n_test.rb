#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::I18nTest < ActiveSupport::TestCase
  include Redmine::I18n
  include ActionView::Helpers::NumberHelper

  def setup
    super
    @hook_module = Redmine::Hook
  end

  def test_date_format_default
    set_language_if_valid 'en'
    today = Date.today
    Setting.date_format = ''
    assert_equal I18n.l(today), format_date(today)
  end

  def test_date_format
    set_language_if_valid 'en'
    today = Date.today
    Setting.date_format = '%d %m %Y'
    assert_equal today.strftime('%d %m %Y'), format_date(today)
  end

  def test_date_and_time_for_each_language
    Setting.date_format = ''
    valid_languages.each do |lang|
      set_language_if_valid lang
      assert_nothing_raised "#{lang} failure" do
        format_date(Date.today)
        format_time(Time.now)
        format_time(Time.now, false)
        assert_not_equal 'default', ::I18n.l(Date.today, :format => :default), "date.formats.default missing in #{lang}"
        assert_not_equal 'time',    ::I18n.l(Time.now, :format => :time),      "time.formats.time missing in #{lang}"
      end
      assert l('date.day_names').is_a?(Array)
      assert_equal 7, l('date.day_names').size

      assert l('date.month_names').is_a?(Array)
      assert_equal 13, l('date.month_names').size
    end
  end

  def test_time_format
    set_language_if_valid 'en'
    now = Time.parse('2011-02-20 15:45:22')
    with_settings :time_format => '%H:%M' do
      with_settings :date_format => '' do
        assert_equal '02/20/2011 15:45', format_time(now)
        assert_equal '15:45', format_time(now, false)
      end

      with_settings :date_format => '%Y-%m-%d' do
        assert_equal '2011-02-20 15:45', format_time(now)
        assert_equal '15:45', format_time(now, false)
      end
    end
  end

  def test_time_format_default
    set_language_if_valid 'en'
    now = Time.parse('2011-02-20 15:45:22')
    with_settings :time_format => '' do
      with_settings :date_format => '' do
        assert_equal '02/20/2011 03:45 PM', format_time(now)
        assert_equal '03:45 PM', format_time(now, false)
      end

      with_settings :date_format => '%Y-%m-%d' do
        assert_equal '2011-02-20 03:45 PM', format_time(now)
        assert_equal '03:45 PM', format_time(now, false)
      end
    end
  end

  def test_time_format
    set_language_if_valid 'en'
    now = Time.now
    with_settings :time_format => '%H %M' do
      with_settings :date_format => '%d %m %Y' do
        assert_equal now.strftime('%d %m %Y %H %M'), format_time(now)
        assert_equal now.strftime('%H %M'), format_time(now, false)
      end
    end
  end

  def test_utc_time_format
    set_language_if_valid 'en'
    now = Time.now
    with_settings :time_format => '%H %M' do
      with_settings :date_format => '%d %m %Y' do
        assert_equal now.strftime('%d %m %Y %H %M'), format_time(now.utc)
        assert_equal now.strftime('%H %M'), format_time(now.utc, false)
      end
    end
  end

  def test_number_to_human_size_for_each_language
    valid_languages.each do |lang|
      set_language_if_valid lang
      assert_nothing_raised "#{lang} failure" do
        number_to_human_size(1024*1024*4)
      end
    end
  end

  def test_valid_languages
    assert valid_languages.is_a?(Array)
    assert valid_languages.first.is_a?(Symbol)
  end

  def test_valid_language
    Setting.available_languages = [:de, :zh]

    to_test = {'de' => :de,
               'DE' => :de,
               'De' => :de,
               'de-ZZ' => nil,
               'zh' => nil }

    to_test.each {|lang, expected| assert_equal expected, find_language(lang)}
  end

  def test_fallback
    ::I18n.backend.store_translations(:en, {:untranslated => "Untranslated string"})
    ::I18n.locale = 'en'
    assert_equal "Untranslated string", l(:untranslated)
    ::I18n.locale = 'de'
    assert_equal "Untranslated string", l(:untranslated)

    ::I18n.backend.store_translations(:de, {:untranslated => "Keine ??bersetzung"})
    ::I18n.locale = 'en'
    assert_equal "Untranslated string", l(:untranslated)
    ::I18n.locale = 'de'
    assert_equal "Keine ??bersetzung", l(:untranslated)
  end
end
