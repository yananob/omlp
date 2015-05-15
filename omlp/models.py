# -*- coding: utf-8 -*-
from datetime import date, timedelta

from pyramid.response import Response
from sqlalchemy import (
    Column,
    Index,
    Integer,
    Text,
    DateTime,
    Boolean,
    and_, create_engine, engine_from_config)
from sqlalchemy.exc import DBAPIError

from sqlalchemy.ext.declarative import declarative_base

from sqlalchemy.orm import (
    scoped_session,
    sessionmaker,
    )

from zope.sqlalchemy import ZopeTransactionExtension


# Constants
STATUS_HOLDING = 2

MAX_RENTABLE_BOOKS = 15
MAX_RESERVABLE_BOOKS = 8

# Variables
DBSession = scoped_session(sessionmaker(extension=ZopeTransactionExtension()))
Base = declarative_base()


# class Book(Base):
#     id = Column(Integer, primary_key=True)
#     book_name = Column(Text)
#     book_id = Column(Text)

class RentBook(Base):
    __tablename__ = 'rent_books'
    id = Column(Integer, primary_key=True)
    oml_acc_id = Column(Integer)
    book_name = Column(Text)
    book_id = Column(Text)
    return_limit_date = Column(DateTime)
    status = Column(Text)

    def is_extended(self):
        return u"延長済" in self.status

    def is_reservation_exist(self):
        return u"次予約有" in self.status

    def is_extendable(self):
        return self.is_reservation_exist == False

    def is_limit_over(self):
        return u"延滞" in self.status

class ReservedBook(Base):
    __tablename__ = 'reserved_books'
    id = Column(Integer, primary_key=True)
    oml_acc_id = Column(Integer)
    book_name = Column(Text)
    book_id = Column(Text)
    hold_limit_date = Column(DateTime)
    status = Column(Text)

    def is_holding(self):
        return u"取置中" in self.status


class OmlAccount(Base):

    __tablename__ = 'oml_accounts'
    id = Column(Integer, primary_key=True)
    omlp_id = Column(Integer)
    oml_id = Column(Text)
    oml_password = Column(Text)
    memo = Column(Text)
    crawled_datetime = Column(DateTime)

    def rent_books(self):
        # TODO: 毎回取得を避ける
        return DBSession.query(RentBook).filter(RentBook.oml_acc_id == self.oml_id).all()

    def reserved_books(self):
        # TODO: 毎回取得を避ける
        return DBSession.query(ReservedBook).filter(ReservedBook.oml_acc_id == self.oml_id).all()

    def is_reservable(self):
        return len(self.reserved_books()) < MAX_RESERVABLE_BOOKS

    def is_holding_reserved(self):
        return self.reserved_books_holding_count() > 0

    def reserved_books_holding_count(self):
        count = 0

        for book in self.reserved_books():
            if book.is_holding():
                count += 1

        return count

    def is_rentable(self):
        return len(self.rent_books()) < MAX_RENTABLE_BOOKS

    def is_near_limit_rent(self):
        return self.rent_books_over_limit_count() > 0

    def rent_books_over_limit_count(self):
        count = 0

        for book in self.rent_books():
            if book.is_limit_over():
                count += 1

        return count

    def update_log(self):
        self.delete_log()

        from omlp.oml_crawler import OmlCrawler
        crawler = OmlCrawler(str(self.oml_id), str(self.oml_password))
        crawler.login()
        # List of Column Object
        books_rent = crawler.get_rent_books()
        books_reserved = crawler.get_reserved_books()

        self.save_log(books_reserved, books_rent)

    def delete_log(self):
        DBSession.query(RentBook).filter(RentBook.oml_acc_id == self.oml_id).delete(synchronize_session=False)
        DBSession.query(ReservedBook).filter(ReservedBook.oml_acc_id == self.oml_id).delete(synchronize_session=False)

    def save_log(self, books_reserved, books_rent):
        for book in books_rent:
            DBSession.add(book)
        for book in books_reserved:
            DBSession.add(book)


class OmlpUser(Base):
    __tablename__ = 'omlp_users'
    id = Column(Integer, primary_key=True)
    email = Column(Text)

    def oml_accounts(self):
        return DBSession.query(OmlAccount).filter(OmlAccount.omlp_id == self.id).all()

    #    :send_day, :send_time, :is_exist

# TODO: omlp.sqliteのGit履歴を消す・・・gihtubに載ってしまう
