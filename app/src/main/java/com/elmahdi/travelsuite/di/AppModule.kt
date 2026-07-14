package com.elmahdi.travelsuite.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import androidx.room.Room
import androidx.work.WorkManager
import com.elmahdi.travelsuite.data.local.AppDatabase
import com.elmahdi.travelsuite.data.local.DB_NAME
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.storage.FirebaseStorage
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.appDataStore: DataStore<Preferences> by preferencesDataStore("travel_suite_prefs")

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, DB_NAME)
            .addMigrations(*AppDatabase.MIGRATIONS)
            .build()

    @Provides fun customerDao(db: AppDatabase) = db.customerDao()
    @Provides fun bookingDao(db: AppDatabase) = db.bookingDao()
    @Provides fun tasaheelDao(db: AppDatabase) = db.tasaheelDao()
    @Provides fun paymentDao(db: AppDatabase) = db.paymentDao()
    @Provides fun debtDao(db: AppDatabase) = db.debtDao()
    @Provides fun userDao(db: AppDatabase) = db.userDao()
    @Provides fun auditLogDao(db: AppDatabase) = db.auditLogDao()

    @Provides @Singleton
    fun provideAuth(): FirebaseAuth = FirebaseAuth.getInstance()

    @Provides @Singleton
    fun provideFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()

    @Provides @Singleton
    fun provideStorage(): FirebaseStorage = FirebaseStorage.getInstance()

    @Provides @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> =
        context.appDataStore

    @Provides @Singleton
    fun provideWorkManager(@ApplicationContext context: Context): WorkManager =
        WorkManager.getInstance(context)
}
