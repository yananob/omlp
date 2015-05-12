# -*- coding: utf-8 -*-
from datetime import date
import mechanize
import re

from .models import (
    DBSession,
    RentBook)

class OmlCrawler():

    def __init__(self, oml_id, oml_password):
        self.browser = mechanize.Browser()
        self.browser.addheaders = [('User-agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36')]

        self.oml_id = oml_id
        self.oml_password = oml_password

    def login(self):
        # TODO: URLErrorで接続エラー処理
        self.browser.open("https://web.oml.city.osaka.lg.jp/webopac/mobidf.do?cmd=init&next=mobasklst")

        self.browser.select_form(name="comidfform")
        self.browser["userid"] = self.oml_id
        self.browser["password"] = self.oml_password
        response = self.browser.submit()

    def get_rent_books(self):
        # TODO: URLErrorで接続エラー処理
        response = self.browser.open("https://web.oml.city.osaka.lg.jp/webopac/moblenlst.do")

        body = response.read()

        rent_books = []

        list_book = re.findall("<strong>資料名</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(body), re.DOTALL)
        # SQlite書式：2015-04-30 00:00:00.000000
        list_limit =  re.findall("<strong>返却期限日</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(body), re.DOTALL)
        # MEMO: 延長済みかどうか　と、予約ありかどうか　が入る
        # TODO: 「状態」はない場合もある・・・・
        # ー>　まとめてFINDALLでなく、１つずつSEARCHしていって、あり・なしを見る必要あり
#        list_status = re.findall("<strong>状態</strong>.+?&nbsp;&nbsp;(.+?)<br/>", str(body), re.DOTALL)

        # TODO: 複数ページ対応
        for i in range(len(list_book)):
            # is_extended = "延長済" in list_status[i]
            # is_reservation_exist = "次予約有" in list_status[i]

            print list_book[i], ":" , list_limit[i]

            limit_date = date(int(list_limit[i][0:4]), int(list_limit[i][5:7]), int(list_limit[i][8:10]))

            rent_book = RentBook(oml_acc_id = self.oml_id,
                                 #book_name = list_book[i],  # DEBUG: Unicode string error ?
                                 return_limit_date =  limit_date)
                                 # is_extended = is_extended, is_reservation_exist = is_reservation_exist)

            rent_books.append(rent_book)

        return rent_books

    def get_reserved_books(self):
        pass
