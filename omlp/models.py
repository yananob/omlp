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

# 自動生成。Transaction must be commited by transaction manager のエラーになるため、修正

DBSession = scoped_session(sessionmaker(extension=ZopeTransactionExtension()))
#DBSession = scoped_session(sessionmaker())
Base = declarative_base()

# engine = engine_from_config(settings, 'sqlalchemy.')
# # http://stackoverflow.com/questions/3033741/sqlalchemy-automatically-converts-str-to-unicode-on-commit
# engine.connect().connection.connection.text_factory = str
# DBSession.configure(bind=engine)
# Base.metadata.bind = engine


# class MyModel(Base):
#     __tablename__ = 'models'
#     id = Column(Integer, primary_key=True)
#     name = Column(Text)
#     value = Column(Integer)
#
# Index('my_index', MyModel.name, unique=True, mysql_length=255)


STATUS_HOLDING = 2

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
    is_extended = Column(Boolean)
    is_reservation_exist = Column(Boolean)

    def is_extendable(self):
        return self.is_reservation_exist == False


class ReservedBook(Base):
    __tablename__ = 'reserved_books'
    id = Column(Integer, primary_key=True)
    oml_acc_id = Column(Integer)
    book_name = Column(Text)
    book_id = Column(Text)
    reserved_date = Column(DateTime)
    reserved_no = Column(Integer)
    status = Column(Integer)
    hold_limit_date = Column(DateTime)

    def is_holding(self):
        return self.status == STATUS_HOLDING


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
        return len(self.reserved_books()) < 8

    def is_holding_reserved(self):
        return self.reserved_books_holding_count() > 0

    def reserved_books_holding_count(self):
        # TODO: 毎回取得を避ける。ReservedBookのメソッドに変える
        return DBSession.query(ReservedBook).filter(and_(ReservedBook.oml_acc_id == self.id,
                                                         ReservedBook.status == STATUS_HOLDING)).count()

    def is_rentable(self):
        return len(self.rent_books()) < 15

    def is_near_limit_rent(self):
        return self.rent_books_near_limit_count() > 0

    def rent_books_near_limit_count(self):
        # TODO: 毎回取得を避ける
        return DBSession.query(RentBook).filter(and_(RentBook.oml_acc_id == self.id,
                                                     RentBook.return_limit_date < date.today() + timedelta(days=2))).count()

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
        for rent_book in books_rent:
            DBSession.add(rent_book)

#	attr_reader :mail, :seq, :oml_id, :oml_pwd, :memo, :crawled, :pass_key
#	attr_writer :crawled


class OmlpUser(Base):
    __tablename__ = 'omlp_users'
    id = Column(Integer, primary_key=True)
    email = Column(Text)

    def oml_accounts(self):
        return DBSession.query(OmlAccount).filter(OmlAccount.omlp_id == self.id).all()

    #    :send_day, :send_time, :is_exist
