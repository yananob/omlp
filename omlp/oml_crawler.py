# -*- coding: utf-8 -*-
from datetime import date
import mechanize
import re

from .models import (
    DBSession,
    RentBook)

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36'

URL_LOGIN = "https://web.oml.city.osaka.lg.jp/webopac/mobidf.do?cmd=init&next=mobasklst"
URL_LIST_RENT_BOOKS = "https://web.oml.city.osaka.lg.jp/webopac/moblenlst.do"


class OmlCrawler():

    def __init__(self, oml_id, oml_password):
        self.browser = mechanize.Browser()
        self.browser.addheaders = [('User-agent', USER_AGENT)]

        self.oml_id = oml_id
        self.oml_password = oml_password

    def login(self):
        # TODO: URLErrorで接続エラー処理
        self.browser.open(URL_LOGIN)

        self.browser.select_form(name="comidfform")
        self.browser["userid"] = self.oml_id
        self.browser["password"] = self.oml_password
        response = self.browser.submit()

    def get_rent_books(self):
        rent_books = []

        # TODO: URLErrorで接続エラー処理
        response = self.browser.open(URL_LIST_RENT_BOOKS)

        while True:
            has_next_button = False
            body = response.read()

            # 「資料名」〜<hr>間の文字を取得し、その中の文字からそれぞれの内容を取得する
            list = re.findall("<strong>資料名</strong>.+?<hr/>", str(body), re.DOTALL)
            for match in list:
                # 資料ID
                # TODO: 値が入っていない。検索文字列が間違い？
                find_book_id =  re.findall("<strong>資料ID</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(match), re.DOTALL)
                if len(find_book_id) == 1:
                    book_id = find_book_id[0]
                else:
                    book_id = ""

                # 書籍名
                find_book_name = re.findall("<strong>資料名</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(match), re.DOTALL)
                book_name = re.sub("[\n\t]", "", unicode(find_book_name[0], "UTF-8"))

                # 貸出期限
                find_limit = re.findall("<strong>返却期限日</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(match), re.DOTALL)
                # SQlite書式：2015-04-30 00:00:00.000000
                limit_date = date(int(find_limit[0][0:4]), int(find_limit[0][5:7]), int(find_limit[0][8:10]))

                # 状態　（延長済みかどうか　と、予約ありかどうか　が入る）
                is_extended = False
                is_reservation_exist = False
                find_status =  re.findall("<strong>状態</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(match), re.DOTALL)
                if len(find_status) == 1:
                    is_extended = "延長済" in find_status[0]
                    is_reservation_exist = "次予約有" in find_status[0]

                rent_book = RentBook(oml_acc_id = self.oml_id,
                                     book_id = book_id,
                                     book_name = book_name,
                                     return_limit_date =  limit_date,
                                     is_extended = is_extended,
                                     is_reservation_exist = is_reservation_exist)
                rent_books.append(rent_book)

            # 次ページがあれば遷移
            if "次へ</a>" not in str(match):
                return rent_books

            response = self.browser.open(URL_LIST_RENT_BOOKS + "?startpos=" + str(len(rent_books) + 1))


    def get_reserved_books(self):
        # TODO: 予約ページ巡回
        pass
