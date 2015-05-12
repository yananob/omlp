from pyramid.response import Response
from pyramid.view import view_config
from sqlalchemy import and_

from sqlalchemy.exc import DBAPIError

from .models import (
    DBSession,
    OmlpUser,
    OmlAccount)

DEBUG_USERID = 1


@view_config(route_name='home', renderer='templates/login.jinja2')
def view_login(request):
    return {'isshowmenu': False}

@view_config(route_name='menu', renderer='templates/menu.jinja2')
def view_menu(request):
    omlp_user = DBSession.query(OmlpUser).filter(OmlpUser.id == DEBUG_USERID).one()

    return {'omlp_user': omlp_user}

# TODO: Cronなどによる自動処理
@view_config(route_name='update_log', renderer='templates/menu.jinja2')
def view_update_log(request):

    oml_account = DBSession.query(OmlAccount).filter(and_(OmlpUser.id == DEBUG_USERID, OmlAccount.id == request.POST["seq"])).one()
    oml_account.update_log()

    return view_menu(request)


conn_err_msg = """\
Pyramid is having a problem using your SQL database.  The problem
might be caused by one of the following things:

1.  You may need to run the "initialize_omlp_db" script
    to initialize your database tables.  Check your virtual
    environment's "bin" directory for this script and try to run it.

2.  Your database server may not be running.  Check that the
    database server referred to by the "sqlalchemy.url" setting in
    your "development.ini" file is running.

After you fix the problem, please restart the Pyramid application to
try it again.
"""

