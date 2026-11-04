#include <jni.h>
#include <string.h>
#include "swephexp.h"

JNIEXPORT void JNICALL
Java_com_astrobond_app_astro_SwissEph_nativeSetPath(JNIEnv *env, jobject thiz, jstring path) {
    const char *p = (*env)->GetStringUTFChars(env, path, NULL);
    swe_set_ephe_path((char *)p);
    // swe_set_ephe_path copies the string internally.
    (*env)->ReleaseStringUTFChars(env, path, p);
}

/* returns [lon, lat, dist, speedLon, speedLat, speedDist]; flags = SEFLG_SPEED like iOS. */
JNIEXPORT jdoubleArray JNICALL
Java_com_astrobond_app_astro_SwissEph_nativeCalcUt(JNIEnv *env, jobject thiz, jdouble jd, jint body, jint flags) {
    double xx[6] = {0, 0, 0, 0, 0, 0};
    char serr[256];
    swe_calc_ut(jd, body, flags, xx, serr);
    jdoubleArray out = (*env)->NewDoubleArray(env, 6);
    (*env)->SetDoubleArrayRegion(env, out, 0, 6, xx);
    return out;
}

/* returns 13 cusps (index 1..12 used) followed by 10 ascmc values => length 23 */
JNIEXPORT jdoubleArray JNICALL
Java_com_astrobond_app_astro_SwissEph_nativeHouses(JNIEnv *env, jobject thiz, jdouble jd, jdouble lat, jdouble lon, jint hsys) {
    double cusps[13] = {0};
    double ascmc[10] = {0};
    swe_houses(jd, lat, lon, hsys, cusps, ascmc);
    double all[23];
    memcpy(all, cusps, sizeof(cusps));
    memcpy(all + 13, ascmc, sizeof(ascmc));
    jdoubleArray out = (*env)->NewDoubleArray(env, 23);
    (*env)->SetDoubleArrayRegion(env, out, 0, 23, all);
    return out;
}
