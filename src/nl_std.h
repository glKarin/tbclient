#ifndef _NL_STD_H
#define _NL_STD_H

#include <QNetworkRequest>

#define _NL_PATCH "7"
#define _NL_RELEASE "20190327"
#define _NL_DEV "karin"
#define _NL_VERS "harmattan"
#define _NL_CODE "FarAwayFromHome"
#define _NL_EMAIL "beyondk2000@gmail.com"
#define _NL_GITHUB "https://github.com/glKarin/tbclient"
#define _NL_PAN "https://pan.baidu.com/s/13RO01jM7SreumvA5sMjGqw 69h2"
#define _NL_OPENREPOS "https://openrepos.net/content/karinzhao/tiebaclientr"

#define _NL_SYMBIAN3_BUILD

#ifdef _KARIN_MM_EXTENSIONS
#define _NL_MULTIMEDIA_EXTENSION
#endif

#define NLSTD_BEGIN_NAMESPACE namespace nlSTD { 
#define NLSTD_END_NAMESPACE }
#define NLSTD_PREPEND_NAMESPACE(x) nlSTD::x

namespace nlSTD
{
	bool create_request(QNetworkRequest *req, const QUrl &source = QUrl());
}

#endif
