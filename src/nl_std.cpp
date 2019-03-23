#include "nl_std.h"

#include <QDebug>

namespace nlSTD
{
	bool create_request(QNetworkRequest *req, const QUrl &source)
	{
		static const QVector<QString> _YoukuSpecialUrl(QVector<QString>() << "ups.youku.com");
		static const QVector<QString> _AcfunSpecialUrl(QVector<QString>() << "acfun");
		static const QVector<QString> _BilibiliSpecialUrl(QVector<QString>() << "bilibili" << "acgvideo");

		bool r;
		QString _host;
		QUrl new_url;
		QByteArray b;
		
		if(!req)
			return false;

		r = false;

		if(!source.isEmpty())
			req->setUrl(source);

    _host = req->url().host(); // qDebug()<<_host;
    if(_YoukuSpecialUrl.contains(_host))
    {
        req->setRawHeader("Referer", "http://v.youku.com");
        req->setRawHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36");
				r = true;
				goto __Exit;
		}
		Q_FOREACH(const QString &s, _AcfunSpecialUrl)
		{
			if(_host.contains(s))
			{
				if(_host == "player.acfun.cn")
				{
					new_url = req->url();
					QList<QPair<QString, QString> >query_items = new_url.queryItems();
					for(QList<QPair<QString, QString> >::iterator itor = query_items.begin();
							itor != query_items.end();
							++itor)
					{
						if(itor->first == "__Referer")
						{
							b.append(itor->second);
							query_items.erase(itor);
							new_url.setQueryItems(query_items);
							req->setUrl(new_url);
							req->setRawHeader("Referer", QByteArray("http://www.acfun.cn/v/ac") + b);
							break;
						}
					}
				}
				req->setRawHeader("User-Agent", "acvideo core/5.0.0(Nokia;TA-1041;7.1.1)");
				req->setRawHeader("deviceType", "1");
				req->setRawHeader("market", "portal");
				req->setRawHeader("appVersion", "5.0.0");
				r = true;
				goto __Exit;
			}
		}
		Q_FOREACH(const QString &s, _BilibiliSpecialUrl)
		{
			if(_host.contains(s))
			{
				req->setRawHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36");
				req->setRawHeader("Referer", "https://www.bilibili.com");
				r = true;
				goto __Exit;
			}
		}

__Exit:
		return r;
	}
}
