from pyramid.config import Configurator
from sqlalchemy import engine_from_config

from .models import (
    DBSession,
    Base,
    )


def main(global_config, **settings):
    """ This function returns a Pyramid WSGI application.
    """
    engine = engine_from_config(settings, 'sqlalchemy.')
    # http://stackoverflow.com/questions/3033741/sqlalchemy-automatically-converts-str-to-unicode-on-commit
    engine.connect().connection.connection.text_factory = str
    DBSession.configure(bind=engine)
    Base.metadata.bind = engine

    config = Configurator(settings=settings)
    config.include('pyramid_jinja2')
    config.include('pyramid_chameleon')
    config.add_static_view('static', 'static', cache_max_age=3600)

    # add route
    config.add_route('home', '/')
    config.add_route('menu', '/menu')
    config.add_route('update_log', '/update_log')

    config.scan()
    return config.make_wsgi_app()
