# -*- coding: utf-8 -*-
from datetime import date, datetime
import mechanize
import re

from .models import (
    DBSession,
    RentBook, ReservedBook)
from omlp.utils import to_unicode

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36'

URL_LOGIN = "https://web.oml.city.osaka.lg.jp/webopac/mobidf.do?cmd=init&next=mobasklst"
URL_LIST_RENT_BOOKS = "https://web.oml.city.osaka.lg.jp/webopac/moblenlst.do"
URL_LIST_RESERVE_BOOKS = "https://web.oml.city.osaka.lg.jp/webopac/mobrsvlst.do"

STR_BOOKS_DELIMITER = "<strong>資料名</strong>.+?<hr/*?>"
STR_FIND_ITEM_FOOT = ".+?&nbsp;&nbsp;(.+?)<br/>"

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

    # 書籍一覧の取得処理。ほぼ、予約と貸出で共通
    def get_books(self, list_books_url, create_field_method):
        books = []
        # TODO: URLErrorで接続エラー処理
        response = self.browser.open(list_books_url)

        while True:
            has_next_button = False
            body = response.read()

            # 「資料名」〜<hr>間の文字を取得し、その中の文字からそれぞれの内容を取得する
            list = re.findall(STR_BOOKS_DELIMITER, str(body), re.DOTALL)
            for match in list:
                book = create_field_method(match)
                books.append(book)

            # 全くループ処理していなければ終了
            if "match" not in locals():
                return books

            # 次ページがあれば遷移
            if "次へ</a>" not in str(match):
                return books

            response = self.browser.open(list_books_url + "?startpos=" + str(len(books) + 1))

    def get_rent_books(self):
        return self.get_books(URL_LIST_RENT_BOOKS, self.create_rent_book)

    def get_reserved_books(self):
        return self.get_books(URL_LIST_RESERVE_BOOKS, self.create_reserve_book)

    def create_rent_book(self, match):
        # 資料ID
        # TODO: 値が入っていない。検索文字列が間違い？
        find_book_id = re.findall("<strong>資料ID</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        if len(find_book_id) == 1:
            book_id = find_book_id[0]
        else:
            book_id = ""

        # 書籍名
        find_book_name = re.findall("<strong>資料名</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        book_name = re.sub("[\n\t]", "", to_unicode(find_book_name[0]))

        # 貸出期限
        find_limit = re.findall("<strong>返却期限日</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        limit_date = datetime.strptime(find_limit[0], "%Y/%m/%d").date()

        # 状態　（延長済みかどうか　と、予約ありかどうか　が入る）
        find_status = re.findall("<strong>状態</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        if len(find_status) == 1:
            status = to_unicode(find_status[0])
        else:
            status = ""

        book = RentBook(oml_acc_id=self.oml_id,
                             book_id=book_id,
                             book_name=book_name,
                             return_limit_date=limit_date,
                             status=status)
        return book

    def create_reserve_book(self, match):
        # 書誌ID
        find_book_id = re.findall("<strong>書誌ID</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        book_id = find_book_id[0]

        # 書籍名
        find_book_name = re.findall("<strong>資料名</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        book_name = re.sub("[\n\t]", "", to_unicode(find_book_name[0]))

        # 取置期限
        find_limit = re.findall("<strong>取置期限日</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        if len(find_limit) == 1:
            limit_date = datetime.strptime(find_limit[0], "%Y/%m/%d").date()
        else:
            limit_date = None

        # 状態　（取り置き中かどうか　が入る）
        find_status = re.findall("<strong>状態</strong>" + STR_FIND_ITEM_FOOT, str(match), re.DOTALL)
        if len(find_status) == 1:
            status = to_unicode(find_status[0])
        else:
            status = ""

        book = ReservedBook(oml_acc_id=self.oml_id,
                            book_id=book_id,
                            book_name=book_name,
                            hold_limit_date=limit_date,
                            status=status)
        return book
